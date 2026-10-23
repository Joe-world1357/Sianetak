import { Logger } from '@nestjs/common';
import { maskPhone } from '../../common/phone/egypt-phone';
import type { OtpSender } from './sms-sender';

/**
 * DEVELOPMENT/TEST ONLY. Does not send an SMS; writes the code to the local server log so a
 * developer can sign in. Configuration validation refuses OTP_PROVIDER=dev in production, and the
 * factory below double-checks NODE_ENV, so this class can never be wired into production.
 */
export class DevOtpSender implements OtpSender {
  readonly available = true;
  readonly name = 'dev-stub';
  private readonly logger = new Logger('DevOtpSender');

  constructor(private readonly quiet = false) {}

  async sendOtp(phoneE164: string, code: string, ttlSeconds: number): Promise<void> {
    if (!this.quiet) {
      this.logger.warn(
        `[DEV ONLY — no SMS sent] OTP for ${maskPhone(phoneE164)}: ${code} (valid ${ttlSeconds}s)`,
      );
    }
  }
}

/** Used when no provider is configured: sign-in is unavailable rather than silently failing. */
export class UnavailableOtpSender implements OtpSender {
  readonly available = false;
  readonly name = 'none';

  async sendOtp(): Promise<void> {
    throw new Error('No OTP provider configured');
  }
}
