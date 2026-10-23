import type { ServiceCategory } from '../catalog/catalog.entities';
import type { AuditLog } from '../audit/audit-log.entity';
import type { ServiceArea } from '../locations/location.entities';
import { presentArea } from '../locations/location.presenter';
import type { MediaFile } from '../media/media.entity';
import type { User } from '../users/user.entity';
import {
  TechnicianDocument,
  TechnicianProfile,
  TechnicianServiceArea,
  TechnicianSpecialty,
  VerificationStatus,
} from './technician.entities';
import { isEligibleTechnician } from './technician.rules';

export type LoadedProfile = Omit<
  TechnicianProfile,
  'user' | 'reviewer' | 'specialties' | 'serviceAreas' | 'documents'
> & {
  user: User;
  reviewer: User | null;
  specialties: (TechnicianSpecialty & { category: ServiceCategory })[];
  serviceAreas: (TechnicianServiceArea & { area: ServiceArea })[];
  documents: (TechnicianDocument & { media: MediaFile })[];
};

const SHOW_REASON = [VerificationStatus.Rejected, VerificationStatus.Suspended];

function core(p: LoadedProfile) {
  return {
    id: p.id,
    status: p.status,
    fullName: p.fullName,
    yearsOfExperience: p.yearsExperience,
    bio: p.bio,
    specialties: p.specialties
      .map((s) => s.category)
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map((c) => ({ id: c.id, slug: c.slug, name: { ar: c.nameAr, en: c.nameEn } })),
    serviceAreas: p.serviceAreas
      .map((a) => a.area)
      .sort((a, b) => a.sortOrder - b.sortOrder)
      .map(presentArea),
    documents: p.documents.map((d) => ({
      id: d.mediaId,
      kind: d.kind,
      contentType: d.media.contentType,
      byteSize: d.media.byteSize,
    })),
    submittedAt: p.submittedAt.toISOString(),
    reviewedAt: p.reviewedAt?.toISOString() ?? null,
  };
}

/** The applicant's own view. */
export function presentOwnApplication(p: LoadedProfile, allowResubmit: boolean) {
  return {
    ...core(p),
    decisionReason: SHOW_REASON.includes(p.status) ? p.decisionReason : null,
    canResubmit: p.status === VerificationStatus.Rejected && allowResubmit,
    eligibleForWork: isEligibleTechnician(p.user, p),
  };
}

export function presentApplicationSummary(p: LoadedProfile) {
  return {
    id: p.id,
    status: p.status,
    fullName: p.fullName,
    specialtyCount: p.specialties.length,
    areaCount: p.serviceAreas.length,
    documentCount: p.documents.length,
    submittedAt: p.submittedAt.toISOString(),
    reviewedAt: p.reviewedAt?.toISOString() ?? null,
  };
}

/** Reviewer view: includes contact details and history. Admin-only. */
export function presentApplicationForReview(p: LoadedProfile, history: AuditLog[]) {
  return {
    ...core(p),
    decisionReason: p.decisionReason,
    applicant: {
      userId: p.user.id,
      phone: p.user.phone,
      accountName: p.user.name,
      accountStatus: p.user.status,
      role: p.user.role,
      memberSince: p.user.createdAt.toISOString(),
    },
    reviewedBy: p.reviewer ? { id: p.reviewer.id, name: p.reviewer.name } : null,
    eligibleForWork: isEligibleTechnician(p.user, p),
    history: history.map((h) => ({
      action: h.action,
      actorId: h.actorId,
      at: h.createdAt.toISOString(),
      reason: typeof h.metadata.reason === 'string' ? h.metadata.reason : null,
    })),
  };
}
