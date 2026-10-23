import type { DataSourceOptions } from 'typeorm';
import type { AppConfig } from '../config/env.validation';
import { OtpChallenge } from '../auth/otp-challenge.entity';
import { RefreshToken } from '../auth/refresh-token.entity';
import { AuditLog } from '../audit/audit-log.entity';
import { Service, ServiceCategory } from '../catalog/catalog.entities';
import { CustomerAddress, ServiceArea } from '../locations/location.entities';
import { MediaFile } from '../media/media.entity';
import {
  ServiceRequest,
  ServiceRequestEvent,
  ServiceRequestPhoto,
} from '../requests/request.entities';
import {
  TechnicianDocument,
  TechnicianProfile,
  TechnicianServiceArea,
  TechnicianSpecialty,
} from '../technicians/technician.entities';
import { User } from '../users/user.entity';
import { SafeTypeOrmLogger } from './safe-typeorm-logger';
import { InitialSchema1761264000000 } from './migrations/1761264000000-InitialSchema';
import { RequestsAndOnboarding1761350400000 } from './migrations/1761350400000-RequestsAndOnboarding';

export const ENTITIES = [
  User,
  OtpChallenge,
  RefreshToken,
  ServiceCategory,
  Service,
  ServiceArea,
  CustomerAddress,
  MediaFile,
  ServiceRequest,
  ServiceRequestPhoto,
  ServiceRequestEvent,
  TechnicianProfile,
  TechnicianSpecialty,
  TechnicianServiceArea,
  TechnicianDocument,
  AuditLog,
];
export const MIGRATIONS = [InitialSchema1761264000000, RequestsAndOnboarding1761350400000];

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
