import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryColumn,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ServiceCategory } from '../catalog/catalog.entities';
import { ServiceArea } from '../locations/location.entities';
import { MediaFile } from '../media/media.entity';
import { User } from '../users/user.entity';

/** Provider verification state (FR-AUTH-06/07, FR-ADM-03). Only `approved` may receive work. */
export enum VerificationStatus {
  PendingReview = 'pending_review',
  Approved = 'approved',
  Rejected = 'rejected',
  Suspended = 'suspended',
}

/**
 * [Proposed] document categories, pending the verification checklist (open decision D-06).
 * Kept deliberately generic: no specific identity document is mandated by the system.
 */
export enum DocumentKind {
  Identity = 'identity',
  Qualification = 'qualification',
  Other = 'other',
}

@Entity({ name: 'technician_profiles' })
export class TechnicianProfile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid', unique: true })
  userId: string;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'user_id' })
  user?: User;

  @Column({ name: 'full_name', type: 'varchar', length: 80 })
  fullName: string;

  @Column({ name: 'years_experience', type: 'int', nullable: true })
  yearsExperience: number | null;

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  @Column({ type: 'varchar', length: 24 })
  status: VerificationStatus;

  @Column({ name: 'submitted_at', type: 'timestamptz' })
  submittedAt: Date;

  @Column({ name: 'reviewed_at', type: 'timestamptz', nullable: true })
  reviewedAt: Date | null;

  @Column({ name: 'reviewed_by', type: 'uuid', nullable: true })
  reviewedBy: string | null;

  @ManyToOne(() => User, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'reviewed_by' })
  reviewer?: User | null;

  /** Required for rejection and suspension; shown to the applicant so they can act on it. */
  @Column({ name: 'decision_reason', type: 'text', nullable: true })
  decisionReason: string | null;

  @Column({ name: 'submission_hash', type: 'char', length: 64 })
  submissionHash: string;

  @OneToMany(() => TechnicianSpecialty, (s) => s.profile)
  specialties?: TechnicianSpecialty[];

  @OneToMany(() => TechnicianServiceArea, (a) => a.profile)
  serviceAreas?: TechnicianServiceArea[];

  @OneToMany(() => TechnicianDocument, (d) => d.profile)
  documents?: TechnicianDocument[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}

@Entity({ name: 'technician_specialties' })
export class TechnicianSpecialty {
  @PrimaryColumn({ name: 'profile_id', type: 'uuid' })
  profileId: string;

  @PrimaryColumn({ name: 'category_id', type: 'uuid' })
  categoryId: string;

  @ManyToOne(() => TechnicianProfile, (p) => p.specialties, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'profile_id' })
  profile?: TechnicianProfile;

  @ManyToOne(() => ServiceCategory, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'category_id' })
  category?: ServiceCategory;
}

@Entity({ name: 'technician_service_areas' })
export class TechnicianServiceArea {
  @PrimaryColumn({ name: 'profile_id', type: 'uuid' })
  profileId: string;

  @PrimaryColumn({ name: 'area_id', type: 'uuid' })
  areaId: string;

  @ManyToOne(() => TechnicianProfile, (p) => p.serviceAreas, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'profile_id' })
  profile?: TechnicianProfile;

  @ManyToOne(() => ServiceArea, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'area_id' })
  area?: ServiceArea;
}

@Entity({ name: 'technician_documents' })
export class TechnicianDocument {
  @PrimaryColumn({ name: 'profile_id', type: 'uuid' })
  profileId: string;

  @PrimaryColumn({ name: 'media_id', type: 'uuid' })
  mediaId: string;

  @Column({ type: 'varchar', length: 24 })
  kind: DocumentKind;

  @ManyToOne(() => TechnicianProfile, (p) => p.documents, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'profile_id' })
  profile?: TechnicianProfile;

  @ManyToOne(() => MediaFile, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'media_id' })
  media?: MediaFile;
}
