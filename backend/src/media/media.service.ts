import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { createHash, randomUUID } from 'node:crypto';
import { EntityManager, IsNull, Repository } from 'typeorm';
import { ApiError } from '../common/errors/api-error';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { User, UserRole } from '../users/user.entity';
import { MEDIA_STORAGE, MediaStorage } from './media-storage';
import { MediaFile, MediaPurpose } from './media.entity';
import { ALLOWED_TYPES, InvalidImageError, sanitizeUpload, sniffContentType } from './media.rules';

/** Who may upload for each purpose. Photos belong to customer requests; documents to applicants. */
const UPLOAD_ROLES: Record<MediaPurpose, UserRole[]> = {
  [MediaPurpose.RequestPhoto]: [UserRole.Customer],
  [MediaPurpose.TechnicianDocument]: [UserRole.Customer, UserRole.Technician],
};

export interface UploadedFile {
  buffer: Buffer;
  size: number;
}

export function presentMedia(m: MediaFile) {
  return {
    id: m.id,
    purpose: m.purpose,
    contentType: m.contentType,
    byteSize: m.byteSize,
    createdAt: m.createdAt.toISOString(),
  };
}

@Injectable()
export class MediaService {
  private readonly logger = new Logger('MediaService');

  constructor(
    @InjectRepository(MediaFile) private readonly repo: Repository<MediaFile>,
    @Inject(MEDIA_STORAGE) private readonly storage: MediaStorage,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  get available() {
    return this.storage.available;
  }

  async upload(user: User, purpose: MediaPurpose, file: UploadedFile | undefined) {
    if (!this.storage.available) {
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'MEDIA_STORAGE_UNAVAILABLE',
        'File uploads are not available',
      );
    }
    if (!UPLOAD_ROLES[purpose].includes(user.role)) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'FORBIDDEN', 'Insufficient role for this upload');
    }
    if (!file || file.size === 0) {
      throw new ApiError(HttpStatus.BAD_REQUEST, 'FILE_REQUIRED', 'A file is required');
    }
    const maxBytes =
      purpose === MediaPurpose.RequestPhoto
        ? this.config.media.maxImageBytes
        : this.config.media.maxDocumentBytes;
    if (file.size > maxBytes) {
      throw new ApiError(HttpStatus.PAYLOAD_TOO_LARGE, 'FILE_TOO_LARGE', 'File is too large', {
        maxBytes,
      });
    }
    const contentType = sniffContentType(file.buffer);
    if (!contentType || !ALLOWED_TYPES[purpose].includes(contentType)) {
      throw new ApiError(
        HttpStatus.UNSUPPORTED_MEDIA_TYPE,
        'UNSUPPORTED_FILE_TYPE',
        'Unsupported file type',
        { allowed: ALLOWED_TYPES[purpose] },
      );
    }
    let data: Buffer;
    try {
      data = sanitizeUpload(contentType, file.buffer);
    } catch (e) {
      if (e instanceof InvalidImageError) {
        throw new ApiError(
          HttpStatus.UNSUPPORTED_MEDIA_TYPE,
          'UNSUPPORTED_FILE_TYPE',
          'The image could not be read',
          { allowed: ALLOWED_TYPES[purpose] },
        );
      }
      throw e;
    }

    const pending = await this.repo.count({ where: { ownerId: user.id, attachedAt: IsNull() } });
    if (pending >= this.config.media.maxPendingPerUser) {
      throw new ApiError(
        HttpStatus.TOO_MANY_REQUESTS,
        'MEDIA_PENDING_LIMIT',
        'Too many unattached uploads; submit or remove some first',
      );
    }

    const storageKey = randomUUID();
    await this.storage.put(storageKey, data);
    try {
      const saved = await this.repo.save(
        this.repo.create({
          ownerId: user.id,
          purpose,
          contentType,
          byteSize: data.length,
          sha256: createHash('sha256').update(data).digest('hex'),
          storageKey,
          attachedAt: null,
        }),
      );
      return presentMedia(saved);
    } catch (e) {
      await this.storage.remove(storageKey);
      throw e;
    }
  }

  /**
   * Locks and binds the caller's own, still-unattached uploads of the given purpose to a new
   * record inside the caller's transaction. Any foreign, reused or wrong-purpose id fails the
   * whole operation with MEDIA_INVALID.
   */
  async claim(em: EntityManager, ownerId: string, ids: string[], purpose: MediaPurpose) {
    if (ids.length === 0) return [];
    if (new Set(ids).size !== ids.length) {
      throw new ApiError(HttpStatus.UNPROCESSABLE_ENTITY, 'MEDIA_INVALID', 'Duplicate file ids');
    }
    const rows = await em
      .getRepository(MediaFile)
      .createQueryBuilder('m')
      .setLock('pessimistic_write')
      .where('m.id IN (:...ids)', { ids })
      .getMany();
    const valid = rows.filter(
      (m) => m.ownerId === ownerId && m.purpose === purpose && m.attachedAt === null,
    );
    if (valid.length !== ids.length) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'MEDIA_INVALID',
        'One or more files cannot be used',
      );
    }
    const now = new Date();
    await em.getRepository(MediaFile).update(ids, { attachedAt: now });
    const byId = new Map(valid.map((m) => [m.id, { ...m, attachedAt: now }]));
    return ids.map((id) => byId.get(id) as MediaFile);
  }

  /**
   * Streams a file to an authorized viewer: its owner, or an admin. Anyone else gets the same
   * 404 as a missing file, so ids cannot be probed. Later sprints extend this for assigned
   * technicians.
   */
  async readContent(viewer: User, id: string) {
    const media = await this.repo.findOneBy({ id });
    if (!media || (media.ownerId !== viewer.id && viewer.role !== UserRole.Admin)) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'MEDIA_NOT_FOUND', 'File not found');
    }
    try {
      return { media, data: await this.storage.read(media.storageKey) };
    } catch (e) {
      this.logger.error(`Stored file unavailable for media ${media.id}: ${(e as Error).name}`);
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'MEDIA_STORAGE_UNAVAILABLE',
        'File is temporarily unavailable',
      );
    }
  }

  /** Removes one of the caller's uploads that is not yet attached (e.g. a photo taken by mistake). */
  async removePending(owner: User, id: string) {
    const media = await this.repo.findOneBy({ id, ownerId: owner.id });
    if (!media) throw new ApiError(HttpStatus.NOT_FOUND, 'MEDIA_NOT_FOUND', 'File not found');
    if (media.attachedAt) {
      throw new ApiError(
        HttpStatus.UNPROCESSABLE_ENTITY,
        'MEDIA_INVALID',
        'Attached files cannot be removed',
      );
    }
    const result = await this.repo.delete({ id, ownerId: owner.id, attachedAt: IsNull() });
    if (result.affected) await this.storage.remove(media.storageKey);
  }
}
