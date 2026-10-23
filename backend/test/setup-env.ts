/** Environment for API integration tests. Uses a dedicated database that tests may truncate. */
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? 'postgres://sianetak:sianetak_dev@localhost:5432/sianetak_test';
process.env.DATABASE_SSL = 'false';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-0123456789-abcdefghijklmnop';
process.env.OTP_PEPPER = 'test-otp-pepper-0123456789-abcdefghijklmnopqrst';
process.env.OTP_PROVIDER = 'dev';
process.env.OTP_DEV_EXPOSE_CODE = 'true';
process.env.OTP_TTL_SECONDS = '300';
process.env.OTP_MAX_VERIFY_ATTEMPTS = '5';
process.env.OTP_RESEND_COOLDOWN_SECONDS = '60';
process.env.OTP_MAX_REQUESTS_PER_HOUR = '5';
process.env.THROTTLE_GLOBAL_PER_MINUTE = '10000';
process.env.THROTTLE_AUTH_PER_MINUTE = '10000';
process.env.CORS_ORIGINS = '';
