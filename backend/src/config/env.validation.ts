/**
 * Typed, validated application configuration.
 *
 * All configuration comes from environment variables (see `.env.example`).
 * Validation fails fast at startup so a misconfigured environment never serves traffic.
 */

export type NodeEnv = 'development' | 'test' | 'production';

/**
 * `dev`  — development/test-only stub: the code is logged locally and may be returned in the API
 *          response. Refused in production.
 * `none` — no SMS provider configured. OTP requests fail with OTP_DELIVERY_UNAVAILABLE.
 *
 * A real SMS provider (e.g. an Egyptian SMS gateway) is not integrated yet; add it as a new value.
 */
export type OtpProvider = 'dev' | 'none';

export interface AppConfig {
  nodeEnv: NodeEnv;
  port: number;
  databaseUrl: string;
  databaseSsl: boolean;
  corsOrigins: string[];
  jwt: {
    accessSecret: string;
    accessTtlSeconds: number;
  };
  refreshTokenTtlDays: number;
  otp: {
    provider: OtpProvider;
    pepper: string;
    length: number;
    ttlSeconds: number;
    maxVerifyAttempts: number;
    resendCooldownSeconds: number;
    maxRequestsPerHour: number;
    /** Only honoured when provider is `dev` and nodeEnv is not production. */
    exposeDevCode: boolean;
  };
  throttle: {
    /** Per-IP limit for all routes, per minute. */
    globalPerMinute: number;
    /** Per-IP limit for OTP request/verify routes, per minute. */
    authPerMinute: number;
  };
}

const MIN_SECRET_LENGTH = 32;

function readInt(
  env: Record<string, string | undefined>,
  key: string,
  fallback: number,
  min: number,
  max: number,
  errors: string[],
): number {
  const raw = env[key];
  if (raw === undefined || raw === '') return fallback;
  const value = Number(raw);
  if (!Number.isInteger(value) || value < min || value > max) {
    errors.push(`${key} must be an integer between ${min} and ${max}`);
    return fallback;
  }
  return value;
}

function readBool(env: Record<string, string | undefined>, key: string, fallback: boolean) {
  const raw = env[key];
  if (raw === undefined || raw === '') return fallback;
  return raw === 'true' || raw === '1';
}

export function validateEnv(env: Record<string, string | undefined>): AppConfig {
  const errors: string[] = [];

  const nodeEnv = (env.NODE_ENV ?? 'development') as NodeEnv;
  if (!['development', 'test', 'production'].includes(nodeEnv)) {
    errors.push('NODE_ENV must be one of development, test, production');
  }
  const isProduction = nodeEnv === 'production';

  const databaseUrl = env.DATABASE_URL ?? '';
  if (!/^postgres(ql)?:\/\//.test(databaseUrl)) {
    errors.push('DATABASE_URL must be a postgres:// connection string');
  }

  const accessSecret = env.JWT_ACCESS_SECRET ?? '';
  if (accessSecret.length < MIN_SECRET_LENGTH) {
    errors.push(`JWT_ACCESS_SECRET must be at least ${MIN_SECRET_LENGTH} characters`);
  }
  const pepper = env.OTP_PEPPER ?? '';
  if (pepper.length < MIN_SECRET_LENGTH) {
    errors.push(`OTP_PEPPER must be at least ${MIN_SECRET_LENGTH} characters`);
  }
  if (accessSecret && accessSecret === pepper) {
    errors.push('JWT_ACCESS_SECRET and OTP_PEPPER must be different');
  }

  const provider = (env.OTP_PROVIDER ?? 'none') as OtpProvider;
  if (!['dev', 'none'].includes(provider)) {
    errors.push('OTP_PROVIDER must be one of dev, none');
  }
  if (isProduction && provider === 'dev') {
    errors.push(
      'OTP_PROVIDER=dev is a development-only stub and is not allowed in production. ' +
        'Configure a real SMS provider before enabling sign-in in production.',
    );
  }

  const corsOrigins = (env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  if (isProduction && corsOrigins.includes('*')) {
    errors.push('CORS_ORIGINS must not contain * in production');
  }

  const config: AppConfig = {
    nodeEnv,
    port: readInt(env, 'PORT', 3000, 1, 65535, errors),
    databaseUrl,
    databaseSsl: readBool(env, 'DATABASE_SSL', isProduction),
    corsOrigins,
    jwt: {
      accessSecret,
      accessTtlSeconds: readInt(env, 'JWT_ACCESS_TTL_SECONDS', 900, 60, 86400, errors),
    },
    refreshTokenTtlDays: readInt(env, 'REFRESH_TOKEN_TTL_DAYS', 30, 1, 365, errors),
    otp: {
      provider,
      pepper,
      length: readInt(env, 'OTP_LENGTH', 6, 4, 8, errors),
      ttlSeconds: readInt(env, 'OTP_TTL_SECONDS', 300, 60, 900, errors),
      maxVerifyAttempts: readInt(env, 'OTP_MAX_VERIFY_ATTEMPTS', 5, 1, 10, errors),
      resendCooldownSeconds: readInt(env, 'OTP_RESEND_COOLDOWN_SECONDS', 60, 0, 600, errors),
      maxRequestsPerHour: readInt(env, 'OTP_MAX_REQUESTS_PER_HOUR', 5, 1, 50, errors),
      exposeDevCode:
        !isProduction && provider === 'dev' && readBool(env, 'OTP_DEV_EXPOSE_CODE', true),
    },
    throttle: {
      globalPerMinute: readInt(env, 'THROTTLE_GLOBAL_PER_MINUTE', 120, 1, 100000, errors),
      authPerMinute: readInt(env, 'THROTTLE_AUTH_PER_MINUTE', 10, 1, 100000, errors),
    },
  };

  if (errors.length > 0) {
    // Messages name the variable only; values are never echoed.
    throw new Error(`Invalid configuration:\n - ${errors.join('\n - ')}`);
  }
  return config;
}

export const APP_CONFIG = Symbol('APP_CONFIG');
