import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * Top-level platform roles (FR-AUTH-05). Finer admin sub-roles (operations, reviewer, finance,
 * support, system administrator) are listed in the SRS but their permission matrix is not yet
 * approved; they will be modelled as admin permissions in a later sprint.
 */
export enum UserRole {
  Customer = 'customer',
  Technician = 'technician',
  Admin = 'admin',
}

export enum UserStatus {
  Active = 'active',
  Suspended = 'suspended',
}

@Entity({ name: 'users' })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** E.164 Egyptian mobile number. Personal data: never log or expose to other users. */
  @Column({ type: 'varchar', length: 16, unique: true })
  phone: string;

  @Column({ type: 'varchar', length: 80, nullable: true })
  name: string | null;

  @Column({ type: 'varchar', length: 16, default: UserRole.Customer })
  role: UserRole;

  @Column({ type: 'varchar', length: 16, default: UserStatus.Active })
  status: UserStatus;

  @Column({ name: 'phone_verified_at', type: 'timestamptz', nullable: true })
  phoneVerifiedAt: Date | null;

  @Column({ name: 'last_sign_in_at', type: 'timestamptz', nullable: true })
  lastSignInAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
