import { validateEnv } from '../../config/env.validation';
import { DevOtpSender, UnavailableOtpSender } from './dev-otp-sender';
import { createOtpSender } from './otp-sender.provider';

const env = {
  DATABASE_URL: 'postgres://u:p@localhost/db',
  JWT_ACCESS_SECRET: 'a'.repeat(32),
  OTP_PEPPER: 'b'.repeat(32),
};

describe('createOtpSender', () => {
  it('uses the dev stub only when explicitly configured outside production', () => {
    expect(
      createOtpSender(validateEnv({ ...env, NODE_ENV: 'development', OTP_PROVIDER: 'dev' })),
    ).toBeInstanceOf(DevOtpSender);
  });

  it('is unavailable when no provider is configured, including in production', () => {
    const dev = createOtpSender(validateEnv({ ...env, NODE_ENV: 'development' }));
    expect(dev).toBeInstanceOf(UnavailableOtpSender);
    expect(dev.available).toBe(false);
    const prod = createOtpSender(
      validateEnv({ ...env, NODE_ENV: 'production', OTP_PROVIDER: 'none' }),
    );
    expect(prod.available).toBe(false);
  });

  it('refuses the dev stub if production config is bypassed', () => {
    const config = validateEnv({ ...env, NODE_ENV: 'development', OTP_PROVIDER: 'dev' });
    expect(() => createOtpSender({ ...config, nodeEnv: 'production' })).toThrow(/production/);
  });
});
