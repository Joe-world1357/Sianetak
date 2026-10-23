import { HttpStatus, Inject, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, Repository } from 'typeorm';
import { AuditAction, AuditService } from '../audit/audit.service';
import { ServiceCategory } from '../catalog/catalog.entities';
import { ApiError } from '../common/errors/api-error';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { LocationsService } from '../locations/locations.service';
import { MediaPurpose } from '../media/media.entity';
import { MediaService } from '../media/media.service';
import { fingerprint } from '../requests/request.rules';
import { User, UserRole } from '../users/user.entity';
import { SubmitApplicationDto } from './dto/application.dto';
import {
  TechnicianDocument,
  TechnicianProfile,
  TechnicianServiceArea,
  TechnicianSpecialty,
  VerificationStatus,
} from './technician.entities';
import {
  LoadedProfile,
  presentApplicationForReview,
  presentApplicationSummary,
  presentOwnApplication,
} from './technician.presenter';
import {
  APPLICANT_ROLES,
  isEligibleTechnician,
  ReviewDecision,
  reviewTransition,
  submitOutcome,
} from './technician.rules';

const RELATIONS = {
  user: true,
  reviewer: true,
  specialties: { category: true },
  serviceAreas: { area: true },
  documents: { media: true },
} as const;

const notFound = () =>
  new ApiError(HttpStatus.NOT_FOUND, 'APPLICATION_NOT_FOUND', 'Application not found');

@Injectable()
export class TechniciansService {
  constructor(
    private readonly dataSource: DataSource,
    @InjectRepository(TechnicianProfile) private readonly profiles: Repository<TechnicianProfile>,
    private readonly locations: LocationsService,
    private readonly media: MediaService,
    private readonly audit: AuditService,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  private load(em: EntityManager, where: { id: string } | { userId: string }) {
    return em.findOne(TechnicianProfile, {
      where,
      relations: RELATIONS,
    }) as Promise<LoadedProfile | null>;
  }

  async getOwn(user: User) {
    const profile = await this.load(this.dataSource.manager, { userId: user.id });
    return {
      application: profile
        ? presentOwnApplication(profile, this.config.technicians.allowResubmitAfterRejection)
        : null,
      requirements: this.requirements(),
    };
  }

  requirements() {
    return {
      minDocuments: this.config.technicians.minDocuments,
      maxDocuments: 10,
      documentKinds: ['identity', 'qualification', 'other'],
      documentContentTypes: ['image/jpeg', 'image/png', 'application/pdf'],
      maxDocumentBytes: this.config.media.maxDocumentBytes,
      uploadsAvailable: this.media.available,
    };
  }

  /**
   * Submits (or, after a rejection, resubmits) the caller's application (FR-AUTH-06). A retried
   * identical submission returns the pending application instead of failing.
   */
  async submit(user: User, dto: SubmitApplicationDto) {
    if (!APPLICANT_ROLES.includes(user.role)) {
      throw new ApiError(
        HttpStatus.FORBIDDEN,
        'APPLICATION_NOT_ALLOWED',
        'This account cannot apply as a technician',
      );
    }
    const hash = fingerprint(dto);
    const allowResubmit = this.config.technicians.allowResubmitAfterRejection;

    return this.dataSource.transaction(async (em) => {
      await em.query('SELECT pg_advisory_xact_lock(hashtextextended($1, 0))', [
        `technician-application:${user.id}`,
      ]);
      const current = await em.findOne(TechnicianProfile, {
        where: { userId: user.id },
        relations: { documents: true },
      });
      const outcome = submitOutcome(current, hash, allowResubmit);
      if (outcome === 'replay') {
        return { created: false, application: await this.presentOwn(em, user.id) };
      }
      if (outcome === 'already_submitted') {
        throw new ApiError(
          HttpStatus.CONFLICT,
          'APPLICATION_ALREADY_SUBMITTED',
          'An application is already under review',
        );
      }
      if (outcome === 'locked') {
        throw new ApiError(
          HttpStatus.CONFLICT,
          'APPLICATION_STATE_CONFLICT',
          'This application can no longer be changed',
          { status: current?.status },
        );
      }

      const documents = dto.documents ?? [];
      if (documents.length < this.config.technicians.minDocuments) {
        throw new ApiError(
          HttpStatus.UNPROCESSABLE_ENTITY,
          'DOCUMENTS_REQUIRED',
          'More verification documents are required',
          { min: this.config.technicians.minDocuments },
        );
      }
      await this.assertActiveCategories(em, dto.specialtyCategoryIds);
      await this.locations.assertActiveAreas(em, dto.serviceAreaIds);

      // Documents already on this application may be kept on resubmission; new ones are claimed.
      const keptIds = new Set(current?.documents?.map((d) => d.mediaId) ?? []);
      const newIds = documents.map((d) => d.mediaId).filter((id) => !keptIds.has(id));
      if (new Set(documents.map((d) => d.mediaId)).size !== documents.length) {
        throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'MEDIA_INVALID', 'Duplicate file ids');
      }
      await this.media.claim(em, user.id, newIds, MediaPurpose.TechnicianDocument);

      const now = new Date();
      const values = {
        fullName: dto.fullName,
        yearsExperience: dto.yearsOfExperience ?? null,
        bio: dto.bio ?? null,
        status: VerificationStatus.PendingReview,
        submittedAt: now,
        reviewedAt: null,
        reviewedBy: null,
        decisionReason: null,
        submissionHash: hash,
      };
      let profileId: string;
      if (current) {
        profileId = current.id;
        await em.update(TechnicianProfile, { id: current.id }, values);
        await em.delete(TechnicianSpecialty, { profileId });
        await em.delete(TechnicianServiceArea, { profileId });
        await em.delete(TechnicianDocument, { profileId });
      } else {
        const created = await em.save(em.create(TechnicianProfile, { userId: user.id, ...values }));
        profileId = created.id;
      }
      await em.insert(
        TechnicianSpecialty,
        dto.specialtyCategoryIds.map((categoryId) => ({ profileId, categoryId })),
      );
      await em.insert(
        TechnicianServiceArea,
        dto.serviceAreaIds.map((areaId) => ({ profileId, areaId })),
      );
      if (documents.length) {
        await em.insert(
          TechnicianDocument,
          documents.map((d) => ({ profileId, mediaId: d.mediaId, kind: d.kind })),
        );
      }
      await this.audit.record(em, {
        actorId: user.id,
        action: current ? 'technician_application.resubmitted' : 'technician_application.submitted',
        targetType: 'technician_profile',
        targetId: profileId,
        metadata: {
          specialtyCount: dto.specialtyCategoryIds.length,
          areaCount: dto.serviceAreaIds.length,
          documentCount: documents.length,
        },
      });
      return { created: !current, application: await this.presentOwn(em, user.id) };
    });
  }

  private async presentOwn(em: EntityManager, userId: string) {
    const profile = (await this.load(em, { userId })) as LoadedProfile;
    return presentOwnApplication(profile, this.config.technicians.allowResubmitAfterRejection);
  }

  private async assertActiveCategories(em: EntityManager, ids: string[]) {
    const count = await em.count(ServiceCategory, { where: { id: In(ids), isActive: true } });
    if (count !== new Set(ids).size) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'CATEGORY_NOT_AVAILABLE',
        'Specialty is not offered',
      );
    }
  }

  // ---- Admin review (FR-ADM-03, FR-ADM-07) ----

  async listForReview(status: VerificationStatus | undefined, limit = 20, offset = 0) {
    const [rows, total] = await this.profiles.findAndCount({
      where: status ? { status } : {},
      relations: RELATIONS,
      // Oldest first, so the queue is worked in arrival order.
      order: { submittedAt: 'ASC', id: 'ASC' },
      take: limit,
      skip: offset,
    });
    return {
      items: (rows as LoadedProfile[]).map(presentApplicationSummary),
      total,
      limit,
      offset,
    };
  }

  async getForReview(id: string) {
    const profile = await this.load(this.dataSource.manager, { id });
    if (!profile) throw notFound();
    const history = await this.audit.list(this.dataSource.manager, 'technician_profile', id);
    return presentApplicationForReview(profile, history);
  }

  /**
   * Applies a reviewer decision atomically: the profile row is locked, the transition checked,
   * the role granted on approval, and an audit record written in the same transaction.
   */
  async review(reviewer: User, id: string, decision: ReviewDecision, reason: string | null) {
    return this.dataSource.transaction(async (em) => {
      const profile = await em.findOne(TechnicianProfile, {
        where: { id },
        lock: { mode: 'pessimistic_write' },
      });
      if (!profile) throw notFound();
      if (profile.userId === reviewer.id) {
        throw new ApiError(
          HttpStatus.FORBIDDEN,
          'CANNOT_REVIEW_OWN_APPLICATION',
          'Reviewers cannot decide their own application',
        );
      }
      const transition = reviewTransition(decision, profile.status);
      if (!transition) {
        throw new ApiError(
          HttpStatus.CONFLICT,
          'APPLICATION_STATE_CONFLICT',
          `Cannot ${decision} an application that is ${profile.status}`,
          { status: profile.status },
        );
      }
      if (transition.reasonRequired && !reason) {
        throw new ApiError(HttpStatus.BAD_REQUEST, 'VALIDATION_FAILED', 'A reason is required', {
          fields: ['reason is required'],
        });
      }
      const fromStatus = profile.status;
      const now = new Date();
      await em.update(
        TechnicianProfile,
        { id, status: fromStatus },
        { status: transition.to, reviewedAt: now, reviewedBy: reviewer.id, decisionReason: reason },
      );
      if (transition.to === VerificationStatus.Approved) {
        // Approval is what grants the technician role; suspension keeps it but removes
        // eligibility through the verification status.
        await em.update(
          User,
          { id: profile.userId, role: In([UserRole.Customer, UserRole.Technician]) },
          { role: UserRole.Technician },
        );
      }
      const action: AuditAction = `technician_application.${
        { approve: 'approved', reject: 'rejected', suspend: 'suspended' }[decision]
      }` as AuditAction;
      await this.audit.record(em, {
        actorId: reviewer.id,
        action,
        targetType: 'technician_profile',
        targetId: id,
        metadata: { fromStatus, toStatus: transition.to, reason },
      });
      const loaded = (await this.load(em, { id })) as LoadedProfile;
      return presentApplicationForReview(
        loaded,
        await this.audit.list(em, 'technician_profile', id),
      );
    });
  }

  /** Eligibility lookup used by ApprovedTechnicianGuard. */
  async isEligible(user: User) {
    const profile = await this.profiles.findOneBy({ userId: user.id });
    return isEligibleTechnician(user, profile);
  }
}
