import { ExecutionContext, SetMetadata } from '@nestjs/common';
import type { ThrottlerModuleOptions } from '@nestjs/throttler';
import type { AppConfig } from '../config/env.validation';

const AUTH_THROTTLE_KEY = 'authThrottle';

/** Applies the stricter per-IP `auth` throttler (in addition to the global one). */
export const AuthThrottle = () => SetMetadata(AUTH_THROTTLE_KEY, true);

const isAuthThrottled = (ctx: ExecutionContext) =>
  Reflect.getMetadata(AUTH_THROTTLE_KEY, ctx.getHandler()) === true;

/**
 * Per-IP throttling. Storage is in-memory: adequate for a single instance; switch to a shared
 * (Redis) store before running more than one API instance. Per-phone OTP limits are enforced
 * separately in the database by AuthService.
 */
export function throttlerOptions(config: AppConfig): ThrottlerModuleOptions {
  return {
    throttlers: [
      { name: 'global', ttl: 60_000, limit: config.throttle.globalPerMinute },
      {
        name: 'auth',
        ttl: 60_000,
        limit: config.throttle.authPerMinute,
        skipIf: (ctx) => !isAuthThrottled(ctx),
      },
    ],
  };
}
