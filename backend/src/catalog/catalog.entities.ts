import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * How a service's price guidance is shown to customers (FR-REQ-06).
 * - `indicative`: an approved EGP range (min/max in piastres) is shown as guidance.
 * - `inspection_required`: no reliable estimate; the customer is told pricing follows inspection.
 */
export enum PricingType {
  Indicative = 'indicative',
  InspectionRequired = 'inspection_required',
}

@Entity({ name: 'service_categories' })
export class ServiceCategory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 64, unique: true })
  slug: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 80 })
  nameAr: string;

  @Column({ name: 'name_en', type: 'varchar', length: 80 })
  nameEn: string;

  @Column({ name: 'description_ar', type: 'text', nullable: true })
  descriptionAr: string | null;

  @Column({ name: 'description_en', type: 'text', nullable: true })
  descriptionEn: string | null;

  /** Client-side icon identifier (e.g. `plumbing`); clients fall back to a generic icon. */
  @Column({ name: 'icon_key', type: 'varchar', length: 40, nullable: true })
  iconKey: string | null;

  @Column({ name: 'sort_order', type: 'int', default: 0 })
  sortOrder: number;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  /** True for placeholder data that has not been approved by operations. */
  @Column({ name: 'is_sample', type: 'boolean', default: false })
  isSample: boolean;

  @OneToMany(() => Service, (s) => s.category)
  services?: Service[];

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}

@Entity({ name: 'services' })
@Index('idx_services_category', ['categoryId', 'sortOrder'])
export class Service {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'category_id', type: 'uuid' })
  categoryId: string;

  @ManyToOne(() => ServiceCategory, (c) => c.services, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'category_id' })
  category?: ServiceCategory;

  @Column({ type: 'varchar', length: 64, unique: true })
  slug: string;

  @Column({ name: 'name_ar', type: 'varchar', length: 120 })
  nameAr: string;

  @Column({ name: 'name_en', type: 'varchar', length: 120 })
  nameEn: string;

  @Column({ name: 'description_ar', type: 'text', nullable: true })
  descriptionAr: string | null;

  @Column({ name: 'description_en', type: 'text', nullable: true })
  descriptionEn: string | null;

  @Column({ name: 'pricing_type', type: 'varchar', length: 24 })
  pricingType: PricingType;

  /** Money in integer minor units (piastres). Null unless pricingType is `indicative`. */
  @Column({ name: 'price_min_minor', type: 'int', nullable: true })
  priceMinMinor: number | null;

  @Column({ name: 'price_max_minor', type: 'int', nullable: true })
  priceMaxMinor: number | null;

  @Column({ type: 'char', length: 3, default: 'EGP' })
  currency: string;

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
