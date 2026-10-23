import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { OTP_SENDER, OtpSender } from '../src/auth/sms/sms-sender';
import { seedSampleCatalog, seedSampleServiceAreas } from '../src/database/seeds/seed-catalog';
import { MEDIA_STORAGE, MediaStorage } from '../src/media/media-storage';
import { UserRole } from '../src/users/user.entity';

export const API = '/api/v1';

export async function createTestApp(
  overrides: { otpSender?: OtpSender; mediaStorage?: MediaStorage } = {},
) {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (overrides.otpSender) {
    builder = builder.overrideProvider(OTP_SENDER).useValue(overrides.otpSender);
  }
  if (overrides.mediaStorage) {
    builder = builder.overrideProvider(MEDIA_STORAGE).useValue(overrides.mediaStorage);
  }
  const moduleRef = await builder.compile();
  const app = moduleRef.createNestApplication({ logger: false });
  setupApp(app);
  await app.init();
  const dataSource = app.get(DataSource);
  await dataSource.runMigrations();
  return { app, dataSource };
}

export async function resetDatabase(dataSource: DataSource, { seed = true } = {}) {
  await dataSource.query(
    `TRUNCATE audit_logs, technician_documents, technician_service_areas, technician_specialties,
      technician_profiles, service_request_events, service_request_photos, service_requests,
      media_files, customer_addresses, service_areas,
      refresh_tokens, otp_challenges, users, services, service_categories CASCADE`,
  );
  if (seed) {
    await seedSampleCatalog(dataSource);
    await seedSampleServiceAreas(dataSource);
  }
}

let phoneCounter = 0;
/** Unique, valid, obviously fake Egyptian mobile numbers for tests. */
export function testPhone() {
  phoneCounter += 1;
  return `0100000${String(phoneCounter).padStart(4, '0')}`;
}

export function requestOtp(app: INestApplication, phone: string) {
  return request(app.getHttpServer()).post(`${API}/auth/otp/request`).send({ phone });
}

export async function signIn(app: INestApplication, phone = testPhone()) {
  const req = await requestOtp(app, phone);
  if (req.status !== 200) throw new Error(`OTP request failed: ${JSON.stringify(req.body)}`);
  const res = await request(app.getHttpServer())
    .post(`${API}/auth/otp/verify`)
    .send({ challengeId: req.body.challengeId, phone, code: req.body.devCode });
  if (res.status !== 200) throw new Error(`OTP verify failed: ${JSON.stringify(res.body)}`);
  return res.body as {
    accessToken: string;
    refreshToken: string;
    isNewUser: boolean;
    user: { id: string; phone: string; role: string };
  };
}

export type Session = Awaited<ReturnType<typeof signIn>>;

export const bearer = (session: Session) => ({ Authorization: `Bearer ${session.accessToken}` });

/** Signs in a fresh account and gives it a role directly in the database (test-only shortcut). */
export async function signInAs(app: INestApplication, dataSource: DataSource, role: UserRole) {
  const session = await signIn(app);
  if (role !== UserRole.Customer) {
    await dataSource.query('UPDATE users SET role = $1 WHERE id = $2', [role, session.user.id]);
  }
  return session;
}

export async function uploadFile(
  app: INestApplication,
  session: Session,
  purpose: string,
  data: Buffer,
  filename = 'photo.jpg',
) {
  return request(app.getHttpServer())
    .post(`${API}/media`)
    .set(bearer(session))
    .field('purpose', purpose)
    .attach('file', data, filename);
}
