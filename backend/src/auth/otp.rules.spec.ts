import {
  challengeUsability,
  decideOtpRequest,
  generateOtpCode,
  hashOtpCode,
  otpHashesMatch,
} from './otp.rules';

const now = new Date('2026-10-23T12:00:00Z');
const secondsAgo = (s: number) => new Date(now.getTime() - s * 1000);
const limits = { resendCooldownSeconds: 60, maxRequestsPerHour: 5 };

describe('generateOtpCode', () => {
  it('produces numeric codes of the configured length, including leading zeros', () => {
    for (let i = 0; i < 200; i++) {
      expect(generateOtpCode(6)).toMatch(/^\d{6}$/);
    }
    expect(generateOtpCode(4)).toMatch(/^\d{4}$/);
  });
});

describe('hashOtpCode', () => {
  const pepper = 'p'.repeat(32);
  it('is deterministic and binds challenge, phone and code', () => {
    const h = hashOtpCode(pepper, 'c1', '+201012345678', '123456');
    expect(h).toHaveLength(64);
    expect(otpHashesMatch(h, hashOtpCode(pepper, 'c1', '+201012345678', '123456'))).toBe(true);
    expect(otpHashesMatch(h, hashOtpCode(pepper, 'c2', '+201012345678', '123456'))).toBe(false);
    expect(otpHashesMatch(h, hashOtpCode(pepper, 'c1', '+201112345678', '123456'))).toBe(false);
    expect(otpHashesMatch(h, hashOtpCode(pepper, 'c1', '+201012345678', '123457'))).toBe(false);
    expect(otpHashesMatch(h, hashOtpCode('q'.repeat(32), 'c1', '+201012345678', '123456'))).toBe(
      false,
    );
  });

  it('does not contain the code in plain text', () => {
    expect(hashOtpCode(pepper, 'c1', '+201012345678', '123456')).not.toContain('123456');
  });
});

describe('challengeUsability', () => {
  const base = {
    attempts: 0,
    maxAttempts: 5,
    expiresAt: new Date(now.getTime() + 60_000),
    consumedAt: null,
    invalidatedAt: null,
  };

  it('is usable when fresh', () => {
    expect(challengeUsability(base, now)).toBe('usable');
  });
  it('is expired at or after expiry', () => {
    expect(challengeUsability({ ...base, expiresAt: now }, now)).toBe('expired');
  });
  it('is expired when superseded by a newer code', () => {
    expect(challengeUsability({ ...base, invalidatedAt: now }, now)).toBe('expired');
  });
  it('is used once consumed, even if not expired', () => {
    expect(challengeUsability({ ...base, consumedAt: now }, now)).toBe('used');
  });
  it('is locked at the attempt limit', () => {
    expect(challengeUsability({ ...base, attempts: 5 }, now)).toBe('locked');
    expect(challengeUsability({ ...base, attempts: 4 }, now)).toBe('usable');
  });
});

describe('decideOtpRequest', () => {
  it('allows the first request', () => {
    expect(
      decideOtpRequest({ lastRequestedAt: null, requestsInLastHour: 0 }, now, limits, null),
    ).toEqual({ allowed: true });
  });

  it('enforces the resend cooldown with retry-after', () => {
    expect(
      decideOtpRequest(
        { lastRequestedAt: secondsAgo(20), requestsInLastHour: 1 },
        now,
        limits,
        secondsAgo(20),
      ),
    ).toEqual({ allowed: false, reason: 'cooldown', retryAfterSeconds: 40 });
  });

  it('allows a resend after the cooldown', () => {
    expect(
      decideOtpRequest(
        { lastRequestedAt: secondsAgo(61), requestsInLastHour: 1 },
        now,
        limits,
        secondsAgo(61),
      ),
    ).toEqual({ allowed: true });
  });

  it('enforces the hourly cap until the oldest request leaves the window', () => {
    expect(
      decideOtpRequest(
        { lastRequestedAt: secondsAgo(120), requestsInLastHour: 5 },
        now,
        limits,
        secondsAgo(3000),
      ),
    ).toEqual({ allowed: false, reason: 'hourly_limit', retryAfterSeconds: 600 });
  });
});
