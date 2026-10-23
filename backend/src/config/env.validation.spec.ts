import { validateEnv } from './env.validation';

const base = {
  NODE_ENV: 'development',
  DATABASE_URL: 'postgres://u:p@localhost:5432/db',
  JWT_ACCESS_SECRET: 'a'.repeat(32),
  OTP_PEPPER: 'b'.repeat(32),
  OTP_PROVIDER: 'dev',
};

describe('validateEnv', () => {
  it('accepts a valid development configuration with defaults', () => {
    const config = validateEnv(base);
    expect(config.otp.ttlSeconds).toBe(300);
    expect(config.otp.maxVerifyAttempts).toBe(5);
    expect(config.otp.exposeDevCode).toBe(true);
  });

  it('refuses the dev OTP stub in production', () => {
    expect(() => validateEnv({ ...base, NODE_ENV: 'production' })).toThrow(
      /OTP_PROVIDER=dev is a development-only stub/,
    );
  });

  it('never exposes the dev code when the provider is not dev', () => {
    const config = validateEnv({ ...base, OTP_PROVIDER: 'none' });
    expect(config.otp.exposeDevCode).toBe(false);
  });

  it('rejects short secrets without echoing their values', () => {
    let message = '';
    try {
      validateEnv({ ...base, JWT_ACCESS_SECRET: 'tooshort-secret-value' });
    } catch (e) {
      message = (e as Error).message;
    }
    expect(message).toMatch(/JWT_ACCESS_SECRET must be at least 32/);
    expect(message).not.toContain('tooshort-secret-value');
  });

  it('rejects reusing the JWT secret as OTP pepper', () => {
    expect(() => validateEnv({ ...base, OTP_PEPPER: base.JWT_ACCESS_SECRET })).toThrow(
      /must be different/,
    );
  });

  it('rejects out-of-range integers', () => {
    expect(() => validateEnv({ ...base, OTP_TTL_SECONDS: '5' })).toThrow(/OTP_TTL_SECONDS/);
  });
});
