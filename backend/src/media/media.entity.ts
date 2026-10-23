import { Column, CreateDateColumn, Entity, PrimaryGeneratedColumn } from 'typeorm';

export enum MediaPurpose {
  RequestPhoto = 'request_photo',
  TechnicianDocument = 'technician_document',
}

export type MediaContentType = 'image/jpeg' | 'image/png' | 'application/pdf';

/**
 * An uploaded private file. The bytes live in MediaStorage under an opaque key; this row is the
 * only way to reach them, through the authorized content endpoint. Never publicly addressable.
 */
@Entity({ name: 'media_files' })
export class MediaFile {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'owner_id', type: 'uuid' })
  ownerId: string;

  @Column({ type: 'varchar', length: 32 })
  purpose: MediaPurpose;

  @Column({ name: 'content_type', type: 'varchar', length: 64 })
  contentType: MediaContentType;

  @Column({ name: 'byte_size', type: 'int' })
  byteSize: number;

  @Column({ type: 'char', length: 64 })
  sha256: string;

  @Column({ name: 'storage_key', type: 'varchar', length: 200, unique: true })
  storageKey: string;

  /** Set once the file is bound to a request or application; it can then no longer be reused. */
  @Column({ name: 'attached_at', type: 'timestamptz', nullable: true })
  attachedAt: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
