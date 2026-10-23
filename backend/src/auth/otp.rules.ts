import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

/** Pure OTP rules, kept free of I/O so they can be unit tested directly. */

export function generateOtpCode(length: number): string {
  return randomInt(0, 10 ** length)
    .toString()
    .padStart(length, '0');
}

/** HMAC binds the code to its challenge and phone, so a leaked hash cannot be replayed elsewhere. */
export function hashOtpCode(pepper: string, challengeId: string, phone: string, code: string) {
  return createHmac('sha256', pepper).update(`${challengeId}:${phone}:${code}`).digest('hex');
}

export function otpHashesMatch(expectedHex: string, actualHex: string): boolean {
  const a = Buffer.from(expectedHex, 'hex');
  const b = Buffer.from(actualHex, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

export interface ChallengeState {
  attempts: number;
  maxAttempts: number;
  expiresAt: Date;
  consumedAt: Date | null;
  invalidatedAt: Date | null;
}

export type ChallengeUsability = 'usable' | 'expired' | 'used' | 'locked';

/**
 * - `used`: already exchanged for a session.
 * - `expired`: past its TTL, or superseded by a newer code.
 * - `locked`: attempt limit reached.
 */
export function challengeUsability(c: ChallengeState, now: Date): ChallengeUsability {
  if (c.consumedAt) return 'used';
  if (c.invalidatedAt || c.expiresAt.getTime() <= now.getTime()) return 'expired';
  if (c.attempts >= c.maxAttempts) return 'locked';
  return 'usable';
}

export interface RequestHistory {
  /** Creation time of the most recent challenge for this phone, if any. */
  lastRequestedAt: Date | null;
  /** Challenges created for this phone in the last hour. */
  requestsInLastHour: number;
}

export type RequestDecision =
  | { allowed: true }
  | { allowed: false; reason: 'cooldown' | 'hourly_limit'; retryAfterSeconds: number };

export function decideOtpRequest(
  history: RequestHistory,
  now: Date,
  limits: { resendCooldownSeconds: number; maxRequestsPerHour: number },
  oldestInWindow: Date | null,
): RequestDecision {
  if (history.lastRequestedAt) {
    const elapsed = (now.getTime() - history.lastRequestedAt.getTime()) / 1000;
    if (elapsed < limits.resendCooldownSeconds) {
      return {
        allowed: false,
        reason: 'cooldown',
        retryAfterSeconds: Math.ceil(limits.resendCooldownSeconds - elapsed),
      };
    }
  }
  if (history.requestsInLastHour >= limits.maxRequestsPerHour) {
    const retry = oldestInWindow
      ? Math.ceil((oldestInWindow.getTime() + 3600_000 - now.getTime()) / 1000)
      : 3600;
    return { allowed: false, reason: 'hourly_limit', retryAfterSeconds: Math.max(1, retry) };
  }
  return { allowed: true };
}
