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

  it('defaults uploads to disabled and refuses local media storage in production', () => {
    expect(validateEnv(base).media.storage).toBe('none');
    expect(() =>
      validateEnv({
        ...base,
        OTP_PROVIDER: 'none',
        NODE_ENV: 'production',
        MEDIA_STORAGE: 'local',
      }),
    ).toThrow(/MEDIA_STORAGE=local is for development and test only/);
  });

  it('parses appointment windows and rejects overlapping ones', () => {
    const config = validateEnv({ ...base, REQUEST_SLOT_WINDOWS: '08:30-10:00,10:00-12:00' });
    expect(config.requests.slotWindows).toEqual([
      { startMinute: 510, endMinute: 600 },
      { startMinute: 600, endMinute: 720 },
    ]);
    expect(() => validateEnv({ ...base, REQUEST_SLOT_WINDOWS: '09:00-12:00,11:00-13:00' })).toThrow(
      /REQUEST_SLOT_WINDOWS/,
    );
  });

  it('leaves the inspection fee undisclosed unless configured', () => {
    expect(validateEnv(base).requests.inspectionFeeMinor).toBeNull();
    expect(validateEnv({ ...base, INSPECTION_FEE_MINOR: '5000' }).requests.inspectionFeeMinor).toBe(
      5000,
    );
  });

  it('rejects malformed region bounds and time zones', () => {
    expect(() => validateEnv({ ...base, SERVICE_REGION_BOUNDS: '24,33,23,32' })).toThrow(
      /SERVICE_REGION_BOUNDS/,
    );
    expect(() => validateEnv({ ...base, REQUEST_TIME_ZONE: 'Mars/Olympus' })).toThrow(
      /REQUEST_TIME_ZONE/,
    );
  });
});
