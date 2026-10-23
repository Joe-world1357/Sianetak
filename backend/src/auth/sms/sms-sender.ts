/** Port for delivering OTP codes. Implementations must never log the code in production. */
export interface OtpSender {
  /** Whether codes can actually be delivered in this environment. */
  readonly available: boolean;
  /** Human-readable provider name for diagnostics (no secrets). */
  readonly name: string;
  sendOtp(phoneE164: string, code: string, ttlSeconds: number): Promise<void>;
}

export const OTP_SENDER = Symbol('OTP_SENDER');
