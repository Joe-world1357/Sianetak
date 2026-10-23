import { INestApplication, LoggerService } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { setupApp } from '../src/app.setup';
import { OTP_SENDER, OtpSender } from '../src/auth/sms/sms-sender';
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

describe('Logs never contain OTPs, phone numbers or tokens', () => {
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
    const ds = app.get(DataSource);
    await ds.runMigrations();
    await resetDatabase(ds);
  });
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
});
