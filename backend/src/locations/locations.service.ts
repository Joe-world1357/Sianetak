import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { EntityManager, IsNull, Repository } from 'typeorm';
import { ApiError } from '../common/errors/api-error';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { AddressInputDto } from './dto/address.dto';
import { CustomerAddress, ServiceArea } from './location.entities';
import { presentAddress, presentArea } from './location.presenter';
import { hasCompleteCoordinates, isWithinBounds, roundCoordinate } from './location.rules';

/** [Proposed] keeps the saved-address list short and bounded. */
export const MAX_SAVED_ADDRESSES = 10;

/** The location fields copied onto a request so later address edits never rewrite history. */
export interface LocationSnapshot {
  addressId: string | null;
  areaId: string;
  details: string;
  landmark: string | null;
  latitude: number | null;
  longitude: number | null;
}

@Injectable()
export class LocationsService {
  constructor(
    @InjectRepository(ServiceArea) private readonly areas: Repository<ServiceArea>,
    @InjectRepository(CustomerAddress) private readonly addresses: Repository<CustomerAddress>,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  async listAreas() {
    const rows = await this.areas.find({
      where: { isActive: true },
      order: { sortOrder: 'ASC', nameEn: 'ASC' },
    });
    return rows.map(presentArea);
  }

  /** Throws AREA_NOT_AVAILABLE unless every id is an active area. */
  async assertActiveAreas(em: EntityManager, ids: string[]) {
    const unique = [...new Set(ids)];
    const count = unique.length
      ? await em
          .getRepository(ServiceArea)
          .createQueryBuilder('a')
          .where('a.id IN (:...ids) AND a.isActive = true', { ids: unique })
          .getCount()
      : 0;
    if (count !== unique.length) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'AREA_NOT_AVAILABLE',
        'Area is not served',
      );
    }
    return unique;
  }

  async listAddresses(userId: string) {
    const rows = await this.addresses.find({
      where: { userId, deletedAt: IsNull() },
      relations: { area: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((a) => presentAddress(a as CustomerAddress & { area: ServiceArea }));
  }

  async createAddress(userId: string, dto: AddressInputDto) {
    return this.addresses.manager.transaction(async (em) => {
      const address = await this.insertAddress(em, userId, dto);
      return presentAddress(address);
    });
  }

  async deleteAddress(userId: string, id: string) {
    const result = await this.addresses.update(
      { id, userId, deletedAt: IsNull() },
      { deletedAt: new Date() },
    );
    if (!result.affected) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'ADDRESS_NOT_FOUND', 'Address not found');
    }
  }

  /** Validates a typed address and returns cleaned values (coordinates rounded). */
  async validateAddressInput(em: EntityManager, dto: AddressInputDto) {
    if (!hasCompleteCoordinates(dto.latitude, dto.longitude)) {
      throw new ApiError(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_FAILED',
        'latitude and longitude must be sent together',
        { fields: ['latitude and longitude must be sent together'] },
      );
    }
    if (
      dto.latitude !== undefined &&
      dto.longitude !== undefined &&
      !isWithinBounds(dto.latitude, dto.longitude, this.config.requests.regionBounds)
    ) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'LOCATION_OUT_OF_AREA',
        'Location is outside the service region',
      );
    }
    await this.assertActiveAreas(em, [dto.areaId]);
    return {
      label: dto.label ?? null,
      areaId: dto.areaId,
      details: dto.details,
      landmark: dto.landmark ?? null,
      latitude: dto.latitude === undefined ? null : roundCoordinate(dto.latitude),
      longitude: dto.longitude === undefined ? null : roundCoordinate(dto.longitude),
    };
  }

  private async insertAddress(em: EntityManager, userId: string, dto: AddressInputDto) {
    const values = await this.validateAddressInput(em, dto);
    // Serialize per user so two concurrent saves cannot both pass the limit check.
    await em.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [`addr:${userId}`]);
    const count = await em.count(CustomerAddress, { where: { userId, deletedAt: IsNull() } });
    if (count >= MAX_SAVED_ADDRESSES) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'ADDRESS_LIMIT_REACHED',
        'Too many saved addresses',
        { max: MAX_SAVED_ADDRESSES },
      );
    }
    const saved = await em.save(em.create(CustomerAddress, { userId, ...values }));
    return em.findOneOrFail(CustomerAddress, {
      where: { id: saved.id },
      relations: { area: true },
    }) as Promise<CustomerAddress & { area: ServiceArea }>;
  }

  /**
   * Resolves the location of a new request: either one of the customer's saved addresses or a
   * newly typed address (optionally saved for next time).
   */
  async resolveForRequest(
    em: EntityManager,
    userId: string,
    input: { addressId?: string; address?: AddressInputDto; saveAddress?: boolean },
  ): Promise<LocationSnapshot> {
    if (input.addressId && input.address) {
      throw new ApiError(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_FAILED',
        'Send either addressId or address, not both',
        { fields: ['Send either addressId or address, not both'] },
      );
    }
    if (input.addressId) {
      const saved = await em.findOne(CustomerAddress, {
        where: { id: input.addressId, userId, deletedAt: IsNull() },
        relations: { area: true },
      });
      if (!saved) {
        throw new ApiError(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'ADDRESS_NOT_FOUND',
          'Address not found',
        );
      }
      if (!saved.area?.isActive) {
        throw new ApiError(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'AREA_NOT_AVAILABLE',
          'Area is not served',
        );
      }
      return {
        addressId: saved.id,
        areaId: saved.areaId,
        details: saved.details,
        landmark: saved.landmark,
        latitude: saved.latitude,
        longitude: saved.longitude,
      };
    }
    if (input.address) {
      if (input.saveAddress) {
        const saved = await this.insertAddress(em, userId, input.address);
        return {
          addressId: saved.id,
          areaId: saved.areaId,
          details: saved.details,
          landmark: saved.landmark,
          latitude: saved.latitude,
          longitude: saved.longitude,
        };
      }
      const values = await this.validateAddressInput(em, input.address);
      return { addressId: null, ...values };
    }
    throw new ApiError(
      HttpStatus.UNPROCESSABLE_ENTITY,
      'LOCATION_REQUIRED',
      'A service address is required',
    );
  }
}
