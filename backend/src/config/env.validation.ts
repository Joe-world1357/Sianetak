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

/**
 * `local` — files on the API server's disk, outside any web root, served only through the
 *           authorized media endpoint. Development/test only; refused in production.
 * `none`  — uploads are disabled (503 MEDIA_STORAGE_UNAVAILABLE); requests without photos work.
 *
 * Private object storage (open infrastructure decision) is not integrated yet; add it as a value.
 */
export type MediaStorageProvider = 'local' | 'none';

/** A bookable appointment window in local service time, as minutes since midnight. */
export interface SlotWindow {
  startMinute: number;
  endMinute: number;
}

export interface RegionBounds {
  minLat: number;
  minLng: number;
  maxLat: number;
  maxLng: number;
}

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
  media: {
    storage: MediaStorageProvider;
    localDir: string;
    maxImageBytes: number;
    maxDocumentBytes: number;
    /** Uploads not yet attached to a request/application, per user (abuse limit). */
    maxPendingPerUser: number;
  };
  requests: {
    /** IANA zone used for appointment slots. Aswan launch market: Africa/Cairo. */
    timeZone: string;
    maxPhotos: number;
    /** [Proposed] anti-abuse cap on a customer's requests that are still open. */
    maxOpenPerCustomer: number;
    scheduleLeadMinutes: number;
    scheduleDaysAhead: number;
    /** [Proposed] appointment windows; operational hours are open decision D-10. */
    slotWindows: SlotWindow[];
    /** Disclosed inspection fee in piastres, or null while D-02 is unapproved. */
    inspectionFeeMinor: number | null;
    /** Coordinates outside this box are rejected (launch coverage, D-01). */
    regionBounds: RegionBounds;
  };
  technicians: {
    /** [Proposed] minimum verification documents; the checklist is open decision D-06. */
    minDocuments: number;
    /** [Proposed] whether a rejected applicant may correct and resubmit (appeal policy TBD). */
    allowResubmitAfterRejection: boolean;
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

function readSlotWindows(raw: string | undefined, errors: string[]): SlotWindow[] {
  const value = raw && raw.trim() ? raw : '09:00-12:00,12:00-15:00,15:00-18:00,18:00-21:00';
  const toMinute = (hhmm: string) => {
    const m = /^([01]\d|2[0-3]):([0-5]\d)$/.exec(hhmm.trim());
    return m ? Number(m[1]) * 60 + Number(m[2]) : NaN;
  };
  const windows = value.split(',').map((part) => {
    const [start, end] = part.split('-');
    return { startMinute: toMinute(start ?? ''), endMinute: toMinute(end ?? '') };
  });
  const valid = windows.every(
    (w, i) =>
      Number.isInteger(w.startMinute) &&
      Number.isInteger(w.endMinute) &&
      w.endMinute > w.startMinute &&
      (i === 0 || w.startMinute >= windows[i - 1].endMinute),
  );
  if (!valid) {
    errors.push('REQUEST_SLOT_WINDOWS must be ordered, non-overlapping HH:MM-HH:MM windows');
    return [];
  }
  return windows;
}

function readBounds(raw: string | undefined, errors: string[]): RegionBounds {
  // Default: an approximate box around Aswan governorate. Replace with the approved coverage.
  const value = raw && raw.trim() ? raw : '22.0,31.3,24.8,33.7';
  const parts = value.split(',').map((p) => Number(p.trim()));
  const [minLat, minLng, maxLat, maxLng] = parts;
  if (
    parts.length !== 4 ||
    parts.some((n) => !Number.isFinite(n)) ||
    minLat >= maxLat ||
    minLng >= maxLng ||
    minLat < -90 ||
    maxLat > 90 ||
    minLng < -180 ||
    maxLng > 180
  ) {
    errors.push('SERVICE_REGION_BOUNDS must be minLat,minLng,maxLat,maxLng');
    return { minLat: 0, minLng: 0, maxLat: 0, maxLng: 0 };
  }
  return { minLat, minLng, maxLat, maxLng };
}

function isValidTimeZone(zone: string) {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: zone });
    return true;
  } catch {
    return false;
  }
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

  const mediaStorage = (env.MEDIA_STORAGE ?? 'none') as MediaStorageProvider;
  if (!['local', 'none'].includes(mediaStorage)) {
    errors.push('MEDIA_STORAGE must be one of local, none');
  }
  if (isProduction && mediaStorage === 'local') {
    errors.push(
      'MEDIA_STORAGE=local is for development and test only. ' +
        'Configure private object storage before enabling uploads in production.',
    );
  }

  const timeZone = env.REQUEST_TIME_ZONE || 'Africa/Cairo';
  if (!isValidTimeZone(timeZone)) {
    errors.push('REQUEST_TIME_ZONE must be a valid IANA time zone');
  }

  const rawFee = env.INSPECTION_FEE_MINOR;
  let inspectionFeeMinor: number | null = null;
  if (rawFee !== undefined && rawFee !== '') {
    inspectionFeeMinor = readInt(env, 'INSPECTION_FEE_MINOR', 0, 0, 10_000_000, errors);
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
    media: {
      storage: mediaStorage,
      localDir: env.MEDIA_LOCAL_DIR || './var/media',
      maxImageBytes: readInt(env, 'MEDIA_MAX_IMAGE_BYTES', 5_242_880, 1024, 26_214_400, errors),
      maxDocumentBytes: readInt(
        env,
        'MEDIA_MAX_DOCUMENT_BYTES',
        10_485_760,
        1024,
        26_214_400,
        errors,
      ),
      maxPendingPerUser: readInt(env, 'MEDIA_MAX_PENDING_PER_USER', 20, 1, 500, errors),
    },
    requests: {
      timeZone,
      maxPhotos: readInt(env, 'REQUEST_MAX_PHOTOS', 5, 0, 10, errors),
      maxOpenPerCustomer: readInt(env, 'REQUEST_MAX_OPEN_PER_CUSTOMER', 5, 1, 100, errors),
      scheduleLeadMinutes: readInt(env, 'REQUEST_SCHEDULE_LEAD_MINUTES', 120, 0, 2880, errors),
      scheduleDaysAhead: readInt(env, 'REQUEST_SCHEDULE_DAYS_AHEAD', 7, 1, 60, errors),
      slotWindows: readSlotWindows(env.REQUEST_SLOT_WINDOWS, errors),
      inspectionFeeMinor,
      regionBounds: readBounds(env.SERVICE_REGION_BOUNDS, errors),
    },
    technicians: {
      minDocuments: readInt(env, 'TECHNICIAN_MIN_DOCUMENTS', 0, 0, 10, errors),
      allowResubmitAfterRejection: readBool(env, 'TECHNICIAN_ALLOW_RESUBMIT', true),
    },
  };

  if (errors.length > 0) {
    // Messages name the variable only; values are never echoed.
    throw new Error(`Invalid configuration:\n - ${errors.join('\n - ')}`);
  }
  return config;
}

export const APP_CONFIG = Symbol('APP_CONFIG');
