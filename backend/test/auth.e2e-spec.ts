import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { OtpChallenge } from '../src/auth/otp-challenge.entity';
import { RefreshToken } from '../src/auth/refresh-token.entity';
import { UnavailableOtpSender } from '../src/auth/sms/dev-otp-sender';
import { User, UserRole, UserStatus } from '../src/users/user.entity';
import { API, createTestApp, requestOtp, resetDatabase, signIn, testPhone } from './helpers';

const toE164 = (local: string) => `+2${local}`;

describe('Auth API', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp());
  });
  beforeEach(() => resetDatabase(dataSource));
  afterAll(() => app.close());

  const http = () => request(app.getHttpServer());
  const verify = (body: Record<string, unknown>) =>
    http().post(`${API}/auth/otp/verify`).send(body);
  const backdateChallenges = (phone: string, seconds: number) =>
    dataSource.query(
      `UPDATE otp_challenges SET created_at = created_at - make_interval(secs => $2) WHERE phone = $1`,
      [toE164(phone), seconds],
    );

  describe('OTP request', () => {
    it('issues a challenge and stores only a hash of the code', async () => {
      const phone = testPhone();
      const res = await requestOtp(app, phone).expect(200);
      expect(res.body).toMatchObject({
        expiresInSeconds: 300,
        resendAfterSeconds: 60,
        codeLength: 6,
      });
      expect(res.body.devCode).toMatch(/^\d{6}$/);
      const row = await dataSource
        .getRepository(OtpChallenge)
        .findOneByOrFail({ id: res.body.challengeId });
      expect(row.phone).toBe(toE164(phone));
      expect(row.codeHash).toHaveLength(64);
      expect(row.codeHash).not.toContain(res.body.devCode);
      expect(row.expiresAt.getTime() - row.createdAt.getTime()).toBeGreaterThanOrEqual(299_000);
    });

    it.each(['', '123', '0221234567', '+966512345678', '01312345678'])(
      'rejects invalid phone %p',
      async (phone) => {
        const res = await requestOtp(app, phone).expect(400);
        expect(res.body.error.code).toBe('INVALID_PHONE');
      },
    );

    it('rejects missing and unexpected fields', async () => {
      const missing = await http().post(`${API}/auth/otp/request`).send({}).expect(400);
      expect(missing.body.error.code).toBe('VALIDATION_FAILED');
      const extra = await http()
        .post(`${API}/auth/otp/request`)
        .send({ phone: testPhone(), role: 'admin' })
        .expect(400);
      expect(extra.body.error.code).toBe('VALIDATION_FAILED');
    });

    it('enforces the resend cooldown per phone', async () => {
      const phone = testPhone();
      await requestOtp(app, phone).expect(200);
      const res = await requestOtp(app, phone).expect(429);
      expect(res.body.error.code).toBe('OTP_RESEND_TOO_SOON');
      expect(res.body.error.details.retryAfterSeconds).toBeGreaterThan(0);
      expect(res.body.error.details.retryAfterSeconds).toBeLessThanOrEqual(60);
      // Another phone is unaffected.
      await requestOtp(app, testPhone()).expect(200);
    });

    it('enforces the hourly cap per phone', async () => {
      const phone = testPhone();
      for (let i = 0; i < 5; i++) {
        await requestOtp(app, phone).expect(200);
        await backdateChallenges(phone, 61);
      }
      const res = await requestOtp(app, phone).expect(429);
      expect(res.body.error.code).toBe('OTP_RATE_LIMITED');
    });

    it('serializes concurrent requests for the same phone', async () => {
      const phone = testPhone();
      const results = await Promise.all([1, 2, 3, 4].map(() => requestOtp(app, phone)));
      expect(results.filter((r) => r.status === 200)).toHaveLength(1);
      expect(results.filter((r) => r.status === 429)).toHaveLength(3);
    });

    it('invalidates the previous code when a new one is issued', async () => {
      const phone = testPhone();
      const first = await requestOtp(app, phone);
      await backdateChallenges(phone, 61);
      const second = await requestOtp(app, phone).expect(200);
      const old = await verify({
        challengeId: first.body.challengeId,
        phone,
        code: first.body.devCode,
      }).expect(400);
      expect(old.body.error.code).toBe('OTP_EXPIRED');
      await verify({
        challengeId: second.body.challengeId,
        phone,
        code: second.body.devCode,
      }).expect(200);
    });
  });

  describe('OTP verify', () => {
    it('signs in a new customer and returns tokens', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      const res = await verify({
        challengeId: otp.body.challengeId,
        phone,
        code: otp.body.devCode,
      }).expect(200);
      expect(res.body).toMatchObject({
        isNewUser: true,
        accessTokenExpiresIn: 900,
        user: { phone: toE164(phone), role: 'customer', status: 'active', name: null },
      });
      expect(res.body.accessToken).toBeTruthy();
      expect(res.body.refreshToken).toBeTruthy();
      const stored = await dataSource.getRepository(RefreshToken).find();
      expect(stored).toHaveLength(1);
      expect(stored[0].tokenHash).not.toBe(res.body.refreshToken);
    });

    it('recognises a returning user and keeps their role', async () => {
      const phone = testPhone();
      const first = await signIn(app, phone);
      await dataSource
        .getRepository(User)
        .update({ id: first.user.id }, { role: UserRole.Technician });
      await backdateChallenges(phone, 61);
      const second = await signIn(app, phone);
      expect(second.isNewUser).toBe(false);
      expect(second.user.id).toBe(first.user.id);
      expect(second.user.role).toBe('technician');
    });

    it('accepts the phone and code typed with Arabic-Indic digits', async () => {
      const phone = '01000009999';
      const otp = await requestOtp(app, '٠١٠٠٠٠٠٩٩٩٩');
      const arabicCode = otp.body.devCode.replace(/\d/g, (d: string) => '٠١٢٣٤٥٦٧٨٩'[Number(d)]);
      await verify({ challengeId: otp.body.challengeId, phone, code: arabicCode }).expect(200);
    });

    it('rejects a wrong code and reports remaining attempts', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      const wrong = otp.body.devCode === '000000' ? '111111' : '000000';
      const res = await verify({ challengeId: otp.body.challengeId, phone, code: wrong }).expect(
        400,
      );
      expect(res.body.error).toMatchObject({
        code: 'OTP_INVALID',
        details: { attemptsRemaining: 4 },
      });
    });

    it('locks the challenge after the maximum attempts, even for the right code', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      const wrong = otp.body.devCode === '000000' ? '111111' : '000000';
      for (let i = 0; i < 4; i++) {
        await verify({ challengeId: otp.body.challengeId, phone, code: wrong }).expect(400);
      }
      const fifth = await verify({ challengeId: otp.body.challengeId, phone, code: wrong }).expect(
        429,
      );
      expect(fifth.body.error.code).toBe('OTP_TOO_MANY_ATTEMPTS');
      const right = await verify({
        challengeId: otp.body.challengeId,
        phone,
        code: otp.body.devCode,
      }).expect(429);
      expect(right.body.error.code).toBe('OTP_TOO_MANY_ATTEMPTS');
    });

    it('counts malformed codes as failed attempts', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      const res = await verify({ challengeId: otp.body.challengeId, phone, code: 'abcd' }).expect(
        400,
      );
      expect(res.body.error.details.attemptsRemaining).toBe(4);
    });

    it('rejects an expired code', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      await dataSource.query(
        `UPDATE otp_challenges SET expires_at = now() - interval '1 second' WHERE id = $1`,
        [otp.body.challengeId],
      );
      const res = await verify({
        challengeId: otp.body.challengeId,
        phone,
        code: otp.body.devCode,
      }).expect(400);
      expect(res.body.error.code).toBe('OTP_EXPIRED');
    });

    it('does not allow a code to be used twice', async () => {
      const phone = testPhone();
      const otp = await requestOtp(app, phone);
      const body = { challengeId: otp.body.challengeId, phone, code: otp.body.devCode };
      await verify(body).expect(200);
      const again = await verify(body).expect(400);
      expect(again.body.error.code).toBe('OTP_EXPIRED');
    });

    it('rejects a challenge presented with a different phone', async () => {
      const otp = await requestOtp(app, testPhone());
      const res = await verify({
        challengeId: otp.body.challengeId,
        phone: testPhone(),
        code: otp.body.devCode,
      }).expect(400);
      expect(res.body.error.code).toBe('OTP_INVALID');
    });

    it('rejects an unknown challenge id and malformed input', async () => {
      const unknown = await verify({
        challengeId: '7d7a3a44-0d0a-4f43-9f3e-6a1b0a4b6c11',
        phone: testPhone(),
        code: '123456',
      }).expect(400);
      expect(unknown.body.error.code).toBe('OTP_INVALID');
      const malformed = await verify({ challengeId: 'nope', phone: testPhone(), code: '1' }).expect(
        400,
      );
      expect(malformed.body.error.code).toBe('VALIDATION_FAILED');
    });

    it('refuses sign-in for a suspended account', async () => {
      const phone = testPhone();
      const { user } = await signIn(app, phone);
      await dataSource
        .getRepository(User)
        .update({ id: user.id }, { status: UserStatus.Suspended });
      await backdateChallenges(phone, 61);
      const otp = await requestOtp(app, phone);
      const res = await verify({
        challengeId: otp.body.challengeId,
        phone,
        code: otp.body.devCode,
      }).expect(403);
      expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
    });
  });

  describe('Sessions', () => {
    it('rotates refresh tokens and detects reuse', async () => {
      const session = await signIn(app);
      const rotated = await http()
        .post(`${API}/auth/refresh`)
        .send({ refreshToken: session.refreshToken })
        .expect(200);
      expect(rotated.body.refreshToken).not.toBe(session.refreshToken);
      expect(rotated.body.user.id).toBe(session.user.id);

      // Reusing the old token fails and revokes the rotated one too.
      const reuse = await http()
        .post(`${API}/auth/refresh`)
        .send({ refreshToken: session.refreshToken })
        .expect(401);
      expect(reuse.body.error.code).toBe('REFRESH_TOKEN_INVALID');
      await http()
        .post(`${API}/auth/refresh`)
        .send({ refreshToken: rotated.body.refreshToken })
        .expect(401);
    });

    it('rejects expired refresh tokens', async () => {
      const session = await signIn(app);
      await dataSource.query(`UPDATE refresh_tokens SET expires_at = now() - interval '1 minute'`);
      await http()
        .post(`${API}/auth/refresh`)
        .send({ refreshToken: session.refreshToken })
        .expect(401);
    });

    it('logout revokes the refresh token and is idempotent', async () => {
      const session = await signIn(app);
      await http()
        .post(`${API}/auth/logout`)
        .send({ refreshToken: session.refreshToken })
        .expect(204);
      await http()
        .post(`${API}/auth/logout`)
        .send({ refreshToken: session.refreshToken })
        .expect(204);
      await http()
        .post(`${API}/auth/refresh`)
        .send({ refreshToken: session.refreshToken })
        .expect(401);
    });
  });

  describe('Protected endpoints and roles', () => {
    it('requires a valid access token', async () => {
      const none = await http().get(`${API}/me`).expect(401);
      expect(none.body.error.code).toBe('UNAUTHENTICATED');
      await http().get(`${API}/me`).set('Authorization', 'Bearer not-a-jwt').expect(401);
      await http().get(`${API}/me`).set('Authorization', 'Basic abc').expect(401);
    });

    it('rejects expired, foreign-signed and non-access tokens', async () => {
      const { user } = await signIn(app);
      const jwt = app.get(JwtService);
      const expired = await jwt.signAsync(
        { sub: user.id, role: 'customer', typ: 'access' },
        { expiresIn: -10 },
      );
      await http().get(`${API}/me`).set('Authorization', `Bearer ${expired}`).expect(401);
      const foreign = new JwtService({ secret: 'x'.repeat(48) });
      const forged = await foreign.signAsync({ sub: user.id, role: 'admin', typ: 'access' });
      await http().get(`${API}/me`).set('Authorization', `Bearer ${forged}`).expect(401);
      const wrongType = await jwt.signAsync({ sub: user.id, role: 'customer', typ: 'refresh' });
      await http().get(`${API}/me`).set('Authorization', `Bearer ${wrongType}`).expect(401);
    });

    it('returns and updates the signed-in profile', async () => {
      const session = await signIn(app);
      const auth = { Authorization: `Bearer ${session.accessToken}` };
      const me = await http().get(`${API}/me`).set(auth).expect(200);
      expect(me.body).toMatchObject({ id: session.user.id, role: 'customer' });
      const updated = await http()
        .patch(`${API}/me`)
        .set(auth)
        .send({ name: '  أحمد   محمد ' })
        .expect(200);
      expect(updated.body.name).toBe('أحمد محمد');
      const bad = await http().patch(`${API}/me`).set(auth).send({ name: '<script>' }).expect(400);
      expect(bad.body.error.code).toBe('VALIDATION_FAILED');
      // Clients cannot change their own role or status.
      await http().patch(`${API}/me`).set(auth).send({ name: 'Ali', role: 'admin' }).expect(400);
    });

    it('blocks suspended users immediately, even with a valid token', async () => {
      const session = await signIn(app);
      await dataSource
        .getRepository(User)
        .update({ id: session.user.id }, { status: UserStatus.Suspended });
      const res = await http()
        .get(`${API}/me`)
        .set('Authorization', `Bearer ${session.accessToken}`)
        .expect(403);
      expect(res.body.error.code).toBe('ACCOUNT_SUSPENDED');
    });

    it('enforces admin-only routes using the role stored server-side', async () => {
      const session = await signIn(app);
      const auth = { Authorization: `Bearer ${session.accessToken}` };
      await http().get(`${API}/admin/catalog/categories`).expect(401);
      const forbidden = await http().get(`${API}/admin/catalog/categories`).set(auth).expect(403);
      expect(forbidden.body.error.code).toBe('FORBIDDEN');

      const users = dataSource.getRepository(User);
      await users.update({ id: session.user.id }, { role: UserRole.Technician });
      await http().get(`${API}/admin/catalog/categories`).set(auth).expect(403);

      // Same token (still says "customer"), but the DB role now grants access.
      await users.update({ id: session.user.id }, { role: UserRole.Admin });
      const ok = await http().get(`${API}/admin/catalog/categories`).set(auth).expect(200);
      expect(ok.body.items[0]).toHaveProperty('isActive');
    });
  });
});

describe('Auth API without an OTP provider', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp({ otpSender: new UnavailableOtpSender() }));
    await resetDatabase(dataSource);
  });
  afterAll(() => app.close());

  it('reports that sign-in is unavailable instead of pretending to send', async () => {
    const res = await requestOtp(app, testPhone()).expect(503);
    expect(res.body.error.code).toBe('OTP_DELIVERY_UNAVAILABLE');
    expect(res.body).not.toHaveProperty('devCode');
    expect(await dataSource.getRepository(OtpChallenge).count()).toBe(0);
  });
});

describe('Auth API when SMS delivery fails', () => {
  let app: INestApplication;
  let dataSource: DataSource;

  beforeAll(async () => {
    ({ app, dataSource } = await createTestApp({
      otpSender: {
        available: true,
        name: 'failing',
        sendOtp: async () => {
          throw new Error('gateway down');
        },
      },
    }));
    await resetDatabase(dataSource);
  });
  afterAll(() => app.close());

  it('returns a retryable error and invalidates the undelivered challenge', async () => {
    const res = await requestOtp(app, testPhone()).expect(503);
    expect(res.body.error.code).toBe('OTP_DELIVERY_FAILED');
    const rows = await dataSource.getRepository(OtpChallenge).find();
    expect(rows).toHaveLength(1);
    expect(rows[0].invalidatedAt).not.toBeNull();
  });
});

describe('Per-IP throttling on OTP endpoints', () => {
  let app: INestApplication;
  let dataSource: DataSource;
  const previous = process.env.THROTTLE_AUTH_PER_MINUTE;

  beforeAll(async () => {
    process.env.THROTTLE_AUTH_PER_MINUTE = '3';
    ({ app, dataSource } = await createTestApp());
    await resetDatabase(dataSource);
  });
  afterAll(async () => {
    process.env.THROTTLE_AUTH_PER_MINUTE = previous;
    await app.close();
  });

  it('limits OTP requests per client IP across phone numbers', async () => {
    for (let i = 0; i < 3; i++) await requestOtp(app, testPhone()).expect(200);
    const res = await requestOtp(app, testPhone()).expect(429);
    expect(res.body.error.code).toBe('RATE_LIMITED');
    // Catalog browsing is not subject to the auth limit.
    await request(app.getHttpServer()).get(`${API}/catalog/categories`).expect(200);
  });
});
