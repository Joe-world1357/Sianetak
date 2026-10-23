import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { OTP_SENDER, OtpSender } from '../src/auth/sms/sms-sender';
import { seedSampleCatalog } from '../src/database/seeds/seed-catalog';

export const API = '/api/v1';

export async function createTestApp(overrides: { otpSender?: OtpSender } = {}) {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (overrides.otpSender) {
    builder = builder.overrideProvider(OTP_SENDER).useValue(overrides.otpSender);
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
    'TRUNCATE refresh_tokens, otp_challenges, users, services, service_categories CASCADE',
  );
  if (seed) await seedSampleCatalog(dataSource);
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
