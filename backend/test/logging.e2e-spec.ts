import { INestApplication, LoggerService } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { OTP_SENDER, OtpSender } from '../src/auth/sms/sms-sender';
import { randomUUID } from 'node:crypto';
import { jpegWithMetadata } from './fixtures/images';
import { API, resetDatabase } from './helpers';

/** Captures everything the app logs so we can assert on what is (not) written. */
class CapturingLogger implements LoggerService {
  lines: string[] = [];
  private push = (...args: unknown[]) => this.lines.push(args.map(String).join(' '));
  log = this.push;
  error = this.push;
  warn = this.push;
  debug = this.push;
  verbose = this.push;
}

/** Stands in for a real SMS gateway: delivers silently, the way a production provider must. */
class SilentSender implements OtpSender {
  readonly available = true;
  readonly name = 'silent-test';
  last?: string;
  async sendOtp(_phone: string, code: string) {
    this.last = code;
  }
}

describe('Logs never contain OTPs, phone numbers, tokens, addresses or uploads', () => {
  let app: INestApplication;
  const logger = new CapturingLogger();
  const sender = new SilentSender();
  const previousExpose = process.env.OTP_DEV_EXPOSE_CODE;

  beforeAll(async () => {
    process.env.OTP_DEV_EXPOSE_CODE = 'false';
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(OTP_SENDER)
      .useValue(sender)
      .compile();
    app = moduleRef.createNestApplication({ logger });
    setupApp(app);
    await app.init();
    dataSource = app.get(DataSource);
    await dataSource.runMigrations();
    await resetDatabase(dataSource);
  });
  let dataSource: DataSource;
  afterAll(async () => {
    process.env.OTP_DEV_EXPOSE_CODE = previousExpose;
    await app.close();
  });

  it('runs a full sign-in flow and checks every log line', async () => {
    const phone = '01099998877';
    const http = () => request(app.getHttpServer());
    const otp = await http().post(`${API}/auth/otp/request`).send({ phone }).expect(200);
    expect(otp.body).not.toHaveProperty('devCode');
    const code = sender.last!;
    await http()
      .post(`${API}/auth/otp/verify`)
      .send({
        challengeId: otp.body.challengeId,
        phone,
        code: code === '000000' ? '111111' : '000000',
      })
      .expect(400);
    const ok = await http()
      .post(`${API}/auth/otp/verify`)
      .send({ challengeId: otp.body.challengeId, phone, code })
      .expect(200);
    await http()
      .get(`${API}/me?phone=${phone}`)
      .set('Authorization', `Bearer ${ok.body.accessToken}`)
      .expect(200);

    const all = logger.lines.join('\n');
    expect(logger.lines.some((l) => l.includes('/auth/otp/verify'))).toBe(true);
    expect(all).not.toContain(code);
    expect(all).not.toContain('1099998877');
    expect(all).not.toContain(ok.body.accessToken);
    expect(all).not.toContain(ok.body.refreshToken);
  });

  it('runs a request submission with a photo and an address and checks every log line', async () => {
    const http = () => request(app.getHttpServer());
    const phone = '01099998866';
    const otp = await http().post(`${API}/auth/otp/request`).send({ phone }).expect(200);
    const session = await http()
      .post(`${API}/auth/otp/verify`)
      .send({ challengeId: otp.body.challengeId, phone, code: sender.last })
      .expect(200);
    const auth = { Authorization: `Bearer ${session.body.accessToken}` };
    const [{ id: serviceId }] = await dataSource.query('SELECT id FROM services LIMIT 1');
    const [{ id: areaId }] = await dataSource.query('SELECT id FROM service_areas LIMIT 1');
    const photo = await http()
      .post(`${API}/media`)
      .set(auth)
      .field('purpose', 'request_photo')
      .attach('file', jpegWithMetadata(), 'my-home-photo.jpg')
      .expect(201);
    logger.lines = [];
    await http()
      .post(`${API}/requests`)
      .set(auth)
      .set('Idempotency-Key', randomUUID())
      .send({
        serviceId,
        description: 'Secret-description-text leaking pipe',
        photoIds: [photo.body.id],
        address: {
          areaId,
          details: 'Private-street-name building 9',
          latitude: 24.0912,
          longitude: 32.8871,
        },
        schedule: { type: 'asap' },
      })
      .expect(201);
    // A validation failure must not echo the submitted address either.
    await http()
      .post(`${API}/me/addresses`)
      .set(auth)
      .send({ areaId: 'bad', details: 'Private-street-name building 9' })
      .expect(400);

    const all = logger.lines.join('\n');
    expect(logger.lines.some((l) => l.includes('POST /api/v1/requests'))).toBe(true);
    expect(all).not.toContain('Private-street-name');
    expect(all).not.toContain('Secret-description-text');
    expect(all).not.toContain('24.0912');
    expect(all).not.toContain('my-home-photo');
    expect(all).not.toContain(session.body.accessToken);
  });
});
