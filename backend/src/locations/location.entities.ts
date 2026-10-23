import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * A configurable operating area (neighbourhood/district) used for request locations and
 * technician coverage. Launch coverage is open decision D-01; seeded rows are samples.
 */
@Entity({ name: 'service_areas' })
export class ServiceArea {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 64, unique: true })
  slug: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 80 })
  nameAr: string;

  @Column({ name: 'name_en', type: 'varchar', length: 80 })
  nameEn: string;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder: number;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @Column({ name: 'is_sample', type: 'boolean', default: false })
  isSample: boolean;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}

/** A customer's saved address (FR-AUTH-04, FR-REQ-04). Personal data: owner and admins only. */
@Entity({ name: 'customer_addresses' })
export class CustomerAddress {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 40, nullable: true })
  label: string | null;

  @Column({ name: 'area_id', type: 'uuid' })
  areaId: string;

  @ManyToOne(() => ServiceArea, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'area_id' })
  area?: ServiceArea;

  @Column({ type: 'varchar', length: 300 })
  details: string;

  @Column({ type: 'varchar', length: 150, nullable: true })
  landmark: string | null;

  @Column({ type: 'double precision', nullable: true })
  latitude: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude: number | null;

  /** Soft delete: requests keep their own snapshot, so deleting never rewrites history. */
  @Column({ name: 'deleted_at', type: 'timestamptz', nullable: true })
  deletedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
