import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Brackets, DataSource, EntityManager, In, Repository } from 'typeorm';
import { Service } from '../catalog/catalog.entities';
import { presentPricing } from '../catalog/catalog.presenter';
import { ApiError } from '../common/errors/api-error';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { LocationsService } from '../locations/locations.service';
import { MediaPurpose } from '../media/media.entity';
import { MediaService } from '../media/media.service';
import type { User } from '../users/user.entity';
import { CreateRequestDto } from './dto/create-request.dto';
import {
  OPEN_STATUSES,
  RequestStatus,
  ScheduleType,
  ServiceRequest,
  ServiceRequestEvent,
  ServiceRequestPhoto,
} from './request.entities';
import { LoadedRequest, presentRequestDetail, presentRequestSummary } from './request.presenter';
import {
  buildSlots,
  DESCRIPTION_MAX_LENGTH,
  DESCRIPTION_MIN_LENGTH,
  fingerprint,
  generateReference,
  isOfferedSlot,
  SlotRules,
} from './request.rules';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const RELATIONS = {
  service: { category: true },
  area: true,
  photos: { media: true },
  events: true,
} as const;

const invalidSchedule = () =>
  new ApiError(
    HttpStatus.UNPROCESSABLE_ENTITY,
    'INVALID_SCHEDULE',
    'Choose one of the offered appointment slots',
  );

@Injectable()
export class RequestsService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(ServiceRequest) private readonly requests: Repository<ServiceRequest>,
    private readonly locations: LocationsService,
    private readonly media: MediaService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  private get slotRules(): SlotRules {
    const r = this.config.requests;
    return {
      timeZone: r.timeZone,
      windows: r.slotWindows,
      leadMinutes: r.scheduleLeadMinutes,
      daysAhead: r.scheduleDaysAhead,
    };
  }

  /** Everything the request form needs to render and validate locally. */
  async options(now = new Date()) {
    const r = this.config.requests;
    return {
      description: { minLength: DESCRIPTION_MIN_LENGTH, maxLength: DESCRIPTION_MAX_LENGTH },
      photos: {
        max: r.maxPhotos,
        maxBytes: this.config.media.maxImageBytes,
        contentTypes: ['image/jpeg', 'image/png'],
        uploadsAvailable: this.media.available,
      },
      schedule: {
        timeZone: r.timeZone,
        asapAvailable: true,
        slots: buildSlots(now, this.slotRules).map((s) => ({
          from: s.from.toISOString(),
          to: s.to.toISOString(),
        })),
      },
      fees: {
        inspectionFee:
          r.inspectionFeeMinor === null
            ? null
            : { amountMinor: r.inspectionFeeMinor, currency: 'EGP' },
      },
      areas: await this.locations.listAreas(),
    };
  }

  /**
   * Creates a request (FR-REQ-02–05, 07, 10). `idempotencyKey` makes retries safe: the same key
   * and payload return the original request; the same key with a different payload is refused.
   */
  async create(customer: User, idempotencyKey: string | undefined, dto: CreateRequestDto) {
    if (!idempotencyKey || !UUID.test(idempotencyKey)) {
      throw new ApiError(
        HttpStatus.BAD_REQUEST,
        'IDEMPOTENCY_KEY_REQUIRED',
        'Send a UUID Idempotency-Key header',
      );
    }
    const key = idempotencyKey.toLowerCase();
    const hash = fingerprint(dto);

    const replay = await this.findReplay(this.dataSource.manager, customer.id, key, hash);
    if (replay) return { created: false, request: replay };

    return this.dataSource.transaction(async (em) => {
      // One submission at a time per customer: closes the race between two retries with the
      // same key, and keeps the open-request cap exact.
      await em.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [
        `request:${customer.id}`,
      ]);
      const raced = await this.findReplay(em, customer.id, key, hash);
      if (raced) return { created: false, request: raced };

      const now = new Date();
      const service = await em.findOne(Service, {
        where: { id: dto.serviceId, isActive: true, category: { isActive: true } },
        relations: { category: true },
      });
      if (!service) {
        throw new ApiError(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'SERVICE_NOT_AVAILABLE',
          'Service is not available',
        );
      }

      const open = await em.count(ServiceRequest, {
        where: { customerId: customer.id, status: In(OPEN_STATUSES) },
      });
      if (open >= this.config.requests.maxOpenPerCustomer) {
        throw new ApiError(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'TOO_MANY_OPEN_REQUESTS',
          'Too many open requests',
          { max: this.config.requests.maxOpenPerCustomer },
        );
      }

      const photoIds = dto.photoIds ?? [];
      if (photoIds.length > this.config.requests.maxPhotos) {
        throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'MEDIA_TOO_MANY', 'Too many photos', {
          max: this.config.requests.maxPhotos,
        });
      }

      let scheduledFrom: Date | null = null;
      let scheduledTo: Date | null = null;
      if (dto.schedule.type === ScheduleType.Scheduled) {
        scheduledFrom = new Date(dto.schedule.from as string);
        scheduledTo = new Date(dto.schedule.to as string);
        if (!isOfferedSlot(scheduledFrom, scheduledTo, now, this.slotRules)) {
          throw invalidSchedule();
        }
      }

      const location = await this.locations.resolveForRequest(em, customer.id, dto);
      const photos = await this.media.claim(em, customer.id, photoIds, MediaPurpose.RequestPhoto);
      const pricing = presentPricing(service);
      const reference = await this.uniqueReference(em, now);

      const request = await em.save(
        em.create(ServiceRequest, {
          reference,
          customerId: customer.id,
          serviceId: service.id,
          status: RequestStatus.Submitted,
          description: dto.description,
          addressId: location.addressId,
          areaId: location.areaId,
          addressDetails: location.details,
          addressLandmark: location.landmark,
          latitude: location.latitude,
          longitude: location.longitude,
          scheduleType: dto.schedule.type,
          scheduledFrom,
          scheduledTo,
          pricingType: pricing.type,
          priceMinMinor: pricing.minMinor ?? null,
          priceMaxMinor: pricing.maxMinor ?? null,
          inspectionFeeMinor: this.config.requests.inspectionFeeMinor,
          currency: 'EGP',
          idempotencyKey: key,
          requestHash: hash,
          submittedAt: now,
        }),
      );
      if (photos.length) {
        await em.insert(
          ServiceRequestPhoto,
          photos.map((m, position) => ({ requestId: request.id, mediaId: m.id, position })),
        );
      }
      await em.insert(ServiceRequestEvent, {
        requestId: request.id,
        actorId: customer.id,
        fromStatus: null,
        toStatus: RequestStatus.Submitted,
        reason: null,
      });
      return { created: true, request: presentRequestDetail(await this.load(em, request.id)) };
    });
  }

  private async findReplay(em: EntityManager, customerId: string, key: string, hash: string) {
    const existing = await em.findOne(ServiceRequest, {
      where: { customerId, idempotencyKey: key },
      relations: RELATIONS,
    });
    if (!existing) return null;
    if (existing.requestHash !== hash) {
      throw new ApiError(
        HttpStatus.CONFLICT,
        'IDEMPOTENCY_KEY_REUSED',
        'This Idempotency-Key was used for a different request',
      );
    }
    return presentRequestDetail(existing as LoadedRequest);
  }

  private async uniqueReference(em: EntityManager, now: Date) {
    for (let attempt = 0; attempt < 5; attempt++) {
      const reference = generateReference(now, this.config.requests.timeZone);
      if (!(await em.existsBy(ServiceRequest, { reference }))) return reference;
    }
    throw new Error('Could not allocate a unique request reference');
  }

  private load(em: EntityManager, id: string) {
    return em.findOneOrFail(ServiceRequest, {
      where: { id },
      relations: RELATIONS,
    }) as Promise<LoadedRequest>;
  }

  /** The customer's own requests, newest first, with an opaque keyset cursor. */
  async listForCustomer(customer: User, limit = 20, cursor?: string) {
    const qb = this.requests
      .createQueryBuilder('r')
      .where('r.customerId = :customerId', { customerId: customer.id })
      .orderBy('r.submittedAt', 'DESC')
      .addOrderBy('r.id', 'DESC')
      .take(limit + 1);
    if (cursor) {
      const [at, id] = Buffer.from(cursor, 'base64url').toString('utf8').split('|');
      const atDate = new Date(at);
      if (!id || !UUID.test(id) || Number.isNaN(atDate.getTime())) {
        throw new ApiError(HttpStatus.BAD_REQUEST, 'VALIDATION_FAILED', 'Invalid cursor', {
          fields: ['cursor is invalid'],
        });
      }
      qb.andWhere(
        new Brackets((w) =>
          w
            .where('r.submittedAt < :at', { at: atDate })
            .orWhere('r.submittedAt = :at AND r.id < :id', { at: atDate, id }),
        ),
      );
    }
    const page = await qb.getMany();
    const hasMore = page.length > limit;
    const ids = page.slice(0, limit).map((r) => r.id);
    const rows = ids.length
      ? ((await this.requests.find({
          where: { id: In(ids) },
          relations: RELATIONS,
        })) as LoadedRequest[])
      : [];
    const byId = new Map(rows.map((r) => [r.id, r]));
    const items = ids.map((id) => presentRequestSummary(byId.get(id) as LoadedRequest));
    const last = page[limit - 1];
    return {
      items,
      nextCursor:
        hasMore && last
          ? Buffer.from(`${last.submittedAt.toISOString()}|${last.id}`).toString('base64url')
          : null,
    };
  }

  /** Owner-only detail. Another user's request is indistinguishable from a missing one. */
  async getForCustomer(customer: User, id: string) {
    const request = await this.requests.findOne({
      where: { id, customerId: customer.id },
      relations: RELATIONS,
    });
    if (!request) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'REQUEST_NOT_FOUND', 'Request not found');
    }
    return presentRequestDetail(request as LoadedRequest);
  }
}
