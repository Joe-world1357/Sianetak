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
import { PricingType, Service } from '../catalog/catalog.entities';
import { ServiceArea } from '../locations/location.entities';
import { MediaFile } from '../media/media.entity';

/**
 * Request lifecycle. Sprint 2 creates requests only; `submitted` corresponds to the SRS `NEW`
 * state before any matching. Dispatch and later states arrive with Sprint 3 and must be added
 * to the database check constraint by migration.
 */
export enum RequestStatus {
  Submitted = 'submitted',
}

/** States in which a request still counts as open for the per-customer cap. */
export const OPEN_STATUSES: RequestStatus[] = [RequestStatus.Submitted];

export enum ScheduleType {
  Asap = 'asap',
  Scheduled = 'scheduled',
}

@Entity({ name: 'service_requests' })
export class ServiceRequest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Human-readable unique reference (FR-REQ-10). */
  @Column({ type: 'varchar', length: 20, unique: true })
  reference: string;

  @Column({ name: 'customer_id', type: 'uuid' })
  customerId: string;

  @Column({ name: 'service_id', type: 'uuid' })
  serviceId: string;

  @ManyToOne(() => Service, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'service_id' })
  service?: Service;

  @Column({ type: 'varchar', length: 24, default: RequestStatus.Submitted })
  status: RequestStatus;

  @Column({ type: 'text' })
  description: string;

  @Column({ name: 'address_id', type: 'uuid', nullable: true })
  addressId: string | null;

  @Column({ name: 'area_id', type: 'uuid' })
  areaId: string;

  @ManyToOne(() => ServiceArea, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'area_id' })
  area?: ServiceArea;

  /** Location snapshot at submission. Precise location: owner, admins (and later the assigned technician) only. */
  @Column({ name: 'address_details', type: 'varchar', length: 300 })
  addressDetails: string;

  @Column({ name: 'address_landmark', type: 'varchar', length: 150, nullable: true })
  addressLandmark: string | null;

  @Column({ type: 'double precision', nullable: true })
  latitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude: number | null;

  @Column({ name: 'schedule_type', type: 'varchar', length: 16 })
  scheduleType: ScheduleType;

  @Column({ name: 'scheduled_from', type: 'timestamptz', nullable: true })
  scheduledFrom: Date | null;

  @Column({ name: 'scheduled_to', type: 'timestamptz', nullable: true })
  scheduledTo: Date | null;

  /** Pricing guidance and fee exactly as disclosed at submission (FR-REQ-07). */
  @Column({ name: 'pricing_type', type: 'varchar', length: 24 })
  pricingType: PricingType;

  @Column({ name: 'price_min_minor', type: 'int', nullable: true })
  priceMinMinor: number | null;

  @Column({ name: 'price_max_minor', type: 'int', nullable: true })
  priceMaxMinor: number | null;

  @Column({ name: 'inspection_fee_minor', type: 'int', nullable: true })
  inspectionFeeMinor: number | null;

  @Column({ type: 'char', length: 3, default: 'EGP' })
  currency: string;

  @Column({ name: 'idempotency_key', type: 'uuid' })
  idempotencyKey: string;

  @Column({ name: 'request_hash', type: 'char', length: 64 })
  requestHash: string;

  @Column({ name: 'submitted_at', type: 'timestamptz' })
  submittedAt: Date;

  @OneToMany(() => ServiceRequestPhoto, (p) => p.request)
  photos?: ServiceRequestPhoto[];

  @OneToMany(() => ServiceRequestEvent, (e) => e.request)
  events?: ServiceRequestEvent[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}

@Entity({ name: 'service_request_photos' })
export class ServiceRequestPhoto {
  @PrimaryColumn({ name: 'request_id', type: 'uuid' })
  requestId: string;

  @PrimaryColumn({ name: 'media_id', type: 'uuid' })
  mediaId: string;

  @Column({ type: 'int' })
  position: number;

  @ManyToOne(() => ServiceRequest, (r) => r.photos, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'request_id' })
  request?: ServiceRequest;

  @ManyToOne(() => MediaFile, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'media_id' })
  media?: MediaFile;
}

/** State history (SRS 3.3): actor, timestamp, transition and reason. */
@Entity({ name: 'service_request_events' })
export class ServiceRequestEvent {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'request_id', type: 'uuid' })
  requestId: string;

  @ManyToOne(() => ServiceRequest, (r) => r.events, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'request_id' })
  request?: ServiceRequest;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId: string | null;

  @Column({ name: 'from_status', type: 'varchar', length: 24, nullable: true })
  fromStatus: RequestStatus | null;

  @Column({ name: 'to_status', type: 'varchar', length: 24 })
  toStatus: RequestStatus;

  @Column({ type: 'text', nullable: true })
  reason: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
