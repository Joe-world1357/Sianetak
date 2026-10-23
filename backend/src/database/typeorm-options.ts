import type { DataSourceOptions } from 'typeorm';
import type { AppConfig } from '../config/env.validation';
import { OtpChallenge } from '../auth/otp-challenge.entity';
import { RefreshToken } from '../auth/refresh-token.entity';
import { Service, ServiceCategory } from '../catalog/catalog.entities';
import { User } from '../users/user.entity';
import { SafeTypeOrmLogger } from './safe-typeorm-logger';
import { InitialSchema1761264000000 } from './migrations/1761264000000-InitialSchema';

export const ENTITIES = [User, OtpChallenge, RefreshToken, ServiceCategory, Service];
export const MIGRATIONS = [InitialSchema1761264000000];

/** Schema changes go through migrations only; `synchronize` is never enabled. */
export function typeormOptions(config: AppConfig): DataSourceOptions {
  return {
    type: 'postgres',
    url: config.databaseUrl,
    ssl: config.databaseSsl ? { rejectUnauthorized: true } : false,
    entities: ENTITIES,
    migrations: MIGRATIONS,
    synchronize: false,
    migrationsRun: false,
    logging: ['error', 'warn', 'migration'],
    logger: new SafeTypeOrmLogger(config.nodeEnv === 'development'),
    maxQueryExecutionTime: 1000,
  };
}
