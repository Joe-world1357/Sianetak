import type { Provider } from '@nestjs/common';
import { APP_CONFIG, AppConfig } from '../../config/env.validation';
import { DevOtpSender, UnavailableOtpSender } from './dev-otp-sender';
import { OTP_SENDER, OtpSender } from './sms-sender';

export function createOtpSender(config: AppConfig): OtpSender {
  if (config.otp.provider === 'dev') {
    if (config.nodeEnv === 'production') {
      throw new Error('Dev OTP sender cannot be used in production');
    }
    return new DevOtpSender(config.nodeEnv === 'test');
  }
  // Add a real SMS gateway implementation here once a provider and credentials are approved.
  return new UnavailableOtpSender();
}

export const otpSenderProvider: Provider = {
  provide: OTP_SENDER,
  inject: [APP_CONFIG],
  useFactory: createOtpSender,
};
