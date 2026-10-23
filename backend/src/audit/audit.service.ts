import { Injectable } from '@nestjs/common';
import { EntityManager } from 'typeorm';
import { AuditLog } from './audit-log.entity';

export type AuditAction =
  | 'technician_application.submitted'
  | 'technician_application.resubmitted'
  | 'technician_application.approved'
  | 'technician_application.rejected'
  | 'technician_application.suspended';

export interface AuditEntry {
  actorId: string | null;
  action: AuditAction;
  targetType: 'technician_profile';
  targetId: string;
  metadata?: Record<string, unknown>;
}

@Injectable()
export class AuditService {
  /** Writes inside the caller's transaction, so the audit row commits with the change itself. */
  record(em: EntityManager, entry: AuditEntry) {
    const row = em.create(AuditLog, { ...entry, metadata: entry.metadata ?? {} });
    return em.save(row);
  }

  list(em: EntityManager, targetType: AuditEntry['targetType'], targetId: string) {
    return em.find(AuditLog, { where: { targetType, targetId }, order: { createdAt: 'ASC' } });
  }
}
