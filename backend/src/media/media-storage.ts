import { Logger, Provider } from '@nestjs/common';
import { mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { APP_CONFIG, AppConfig } from '../config/env.validation';

/** Port for private file storage. Keys are opaque server-generated UUIDs. */
export interface MediaStorage {
  readonly available: boolean;
  put(key: string, data: Buffer): Promise<void>;
  read(key: string): Promise<Buffer>;
  remove(key: string): Promise<void>;
}

export const MEDIA_STORAGE = Symbol('MEDIA_STORAGE');

const KEY = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

/**
 * DEVELOPMENT/TEST storage on the API server's disk, outside any served directory. Files are
 * created owner-read/write only. Refused in production by configuration validation.
 */
export class LocalDiskMediaStorage implements MediaStorage {
  readonly available = true;
  private readonly root: string;

  constructor(dir: string) {
    this.root = resolve(dir);
  }

  private path(key: string) {
    if (!KEY.test(key)) throw new Error('Invalid storage key');
    return join(this.root, key);
  }

  async put(key: string, data: Buffer) {
    await mkdir(this.root, { recursive: true, mode: 0o700 });
    await writeFile(this.path(key), data, { mode: 0o600, flag: 'wx' });
  }

  read(key: string) {
    return readFile(this.path(key));
  }

  async remove(key: string) {
    await rm(this.path(key), { force: true });
  }
}

/** No storage configured: uploads are refused with MEDIA_STORAGE_UNAVAILABLE. */
export class UnavailableMediaStorage implements MediaStorage {
  readonly available = false;
  put(): Promise<void> {
    return Promise.reject(new Error('Media storage is not configured'));
  }
  read(): Promise<Buffer> {
    return Promise.reject(new Error('Media storage is not configured'));
  }
  async remove() {
    // Nothing stored.
  }
}

export const mediaStorageProvider: Provider = {
  provide: MEDIA_STORAGE,
  inject: [APP_CONFIG],
  useFactory: (config: AppConfig): MediaStorage => {
    if (config.media.storage === 'local') {
      new Logger('MediaStorage').warn(
        'MEDIA_STORAGE=local: uploads are kept on this server’s disk (development/test only).',
      );
      return new LocalDiskMediaStorage(config.media.localDir);
    }
    return new UnavailableMediaStorage();
  },
};
