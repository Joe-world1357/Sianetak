import { HttpStatus, Inject, Injectable, Logger } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { DataSource, IsNull, MoreThan } from 'typeorm';
import { ApiError } from '../common/errors/api-error';
import { normalizeEgyptMobile, toAsciiDigits } from '../common/phone/egypt-phone';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { User, UserStatus } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { OtpChallenge } from './otp-challenge.entity';
import {
  challengeUsability,
  decideOtpRequest,
  generateOtpCode,
  hashOtpCode,
  otpHashesMatch,
} from './otp.rules';
import { OTP_SENDER, OtpSender } from './sms/sms-sender';
import { TokenPair, TokenService } from './token.service';

export interface OtpRequestResult {
  challengeId: string;
  expiresAt: string;
  expiresInSeconds: number;
  resendAfterSeconds: number;
  codeLength: number;
  /** Present only with the development OTP stub outside production. */
  devCode?: string;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger('AuthService');

  constructor(
    private readonly dataSource: DataSource,
    private readonly users: UsersService,
    private readonly tokens: TokenService,
    @Inject(OTP_SENDER) private readonly sender: OtpSender,
    @Inject(APP_CONFIG) private readonly config: AppConfig,
  ) {}

  private parsePhone(raw: unknown): string {
    const phone = normalizeEgyptMobile(raw);
    if (!phone) {
      throw new ApiError(
        HttpStatus.BAD_REQUEST,
        'INVALID_PHONE',
        'Enter a valid Egyptian mobile number',
      );
    }
    return phone;
  }

  async requestOtp(rawPhone: unknown): Promise<OtpRequestResult> {
    const phone = this.parsePhone(rawPhone);
    if (!this.sender.available) {
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'OTP_DELIVERY_UNAVAILABLE',
        'Sign-in by SMS is not available yet',
      );
    }
    const { length, ttlSeconds, maxVerifyAttempts, resendCooldownSeconds, maxRequestsPerHour } =
      this.config.otp;
    const code = generateOtpCode(length);

    const challenge = await this.dataSource.transaction(async (em) => {
      // Serialize requests per phone so concurrent calls cannot bypass the limits.
      await em.query('SELECT pg_advisory_xact_lock(hashtext($1))', [`otp:${phone}`]);
      const now = new Date();
      const windowStart = new Date(now.getTime() - 3600_000);
      const recent = await em.find(OtpChallenge, {
        where: { phone, createdAt: MoreThan(windowStart) },
        order: { createdAt: 'ASC' },
        select: { id: true, createdAt: true },
      });
      const decision = decideOtpRequest(
        {
          lastRequestedAt: recent.at(-1)?.createdAt ?? null,
          requestsInLastHour: recent.length,
        },
        now,
        { resendCooldownSeconds, maxRequestsPerHour },
        recent[0]?.createdAt ?? null,
      );
      if (!decision.allowed) {
        throw new ApiError(
          HttpStatus.TOO_MANY_REQUESTS,
          decision.reason === 'cooldown' ? 'OTP_RESEND_TOO_SOON' : 'OTP_RATE_LIMITED',
          decision.reason === 'cooldown'
            ? 'Wait before requesting another code'
            : 'Too many codes requested for this number',
          { retryAfterSeconds: decision.retryAfterSeconds },
        );
      }

      // Only the newest code is valid.
      await em.update(
        OtpChallenge,
        { phone, consumedAt: IsNull(), invalidatedAt: IsNull() },
        { invalidatedAt: now },
      );
      const id = randomUUID();
      return em.save(
        em.create(OtpChallenge, {
          id,
          phone,
          codeHash: hashOtpCode(this.config.otp.pepper, id, phone, code),
          attempts: 0,
          maxAttempts: maxVerifyAttempts,
          expiresAt: new Date(now.getTime() + ttlSeconds * 1000),
        }),
      );
    });

    try {
      await this.sender.sendOtp(phone, code, ttlSeconds);
    } catch (err) {
      await this.dataSource
        .getRepository(OtpChallenge)
        .update({ id: challenge.id }, { invalidatedAt: new Date() });
      this.logger.error(
        `OTP delivery failed via ${this.sender.name} (challenge ${challenge.id}): ${(err as Error).name}`,
      );
      throw new ApiError(
        HttpStatus.SERVICE_UNAVAILABLE,
        'OTP_DELIVERY_FAILED',
        'Could not send the code, try again',
      );
    }

    return {
      challengeId: challenge.id,
      expiresAt: challenge.expiresAt.toISOString(),
      expiresInSeconds: ttlSeconds,
      resendAfterSeconds: resendCooldownSeconds,
      codeLength: length,
      ...(this.config.otp.exposeDevCode ? { devCode: code } : {}),
    };
  }

  async verifyOtp(
    challengeId: string,
    rawPhone: unknown,
    rawCode: string,
  ): Promise<{ user: User; tokens: TokenPair; isNewUser: boolean }> {
    const phone = this.parsePhone(rawPhone);
    const code = toAsciiDigits(rawCode).trim();
    const codePattern = new RegExp(`^\\d{${this.config.otp.length}}$`);

    const outcome = await this.dataSource.transaction(async (em) => {
      const challenge = await em.findOne(OtpChallenge, {
        where: { id: challengeId },
        lock: { mode: 'pessimistic_write' },
      });
      // Unknown challenge or mismatched phone: same generic answer, no enumeration.
      if (!challenge || challenge.phone !== phone) {
        return { error: 'OTP_INVALID' as const, attemptsRemaining: undefined };
      }
      const now = new Date();
      const usability = challengeUsability(challenge, now);
      if (usability === 'used' || usability === 'expired') return { error: 'OTP_EXPIRED' as const };
      if (usability === 'locked') return { error: 'OTP_TOO_MANY_ATTEMPTS' as const };

      challenge.attempts += 1;
      const matches =
        codePattern.test(code) &&
        otpHashesMatch(
          challenge.codeHash,
          hashOtpCode(this.config.otp.pepper, challenge.id, phone, code),
        );
      if (!matches) {
        await em.update(OtpChallenge, { id: challenge.id }, { attempts: challenge.attempts });
        const attemptsRemaining = challenge.maxAttempts - challenge.attempts;
        return attemptsRemaining > 0
          ? { error: 'OTP_INVALID' as const, attemptsRemaining }
          : { error: 'OTP_TOO_MANY_ATTEMPTS' as const };
      }

      await em.update(
        OtpChallenge,
        { id: challenge.id },
        { attempts: challenge.attempts, consumedAt: now },
      );
      const existed = await em.existsBy(User, { phone });
      const user = await this.users.findOrCreateCustomerByPhone(em, phone, now);
      if (user.status !== UserStatus.Active) return { error: 'ACCOUNT_SUSPENDED' as const };
      const tokens = await this.tokens.issue(em, user);
      return { user, tokens, isNewUser: !existed };
    });

    // Errors are raised after commit so the attempt counter is always persisted.
    if ('error' in outcome) {
      switch (outcome.error) {
        case 'OTP_INVALID':
          throw new ApiError(
            HttpStatus.BAD_REQUEST,
            'OTP_INVALID',
            'The code is incorrect',
            outcome.attemptsRemaining !== undefined
              ? { attemptsRemaining: outcome.attemptsRemaining }
              : undefined,
          );
        case 'OTP_EXPIRED':
          throw new ApiError(
            HttpStatus.BAD_REQUEST,
            'OTP_EXPIRED',
            'The code has expired, request a new one',
          );
        case 'OTP_TOO_MANY_ATTEMPTS':
          throw new ApiError(
            HttpStatus.TOO_MANY_REQUESTS,
            'OTP_TOO_MANY_ATTEMPTS',
            'Too many incorrect attempts, request a new code',
          );
        case 'ACCOUNT_SUSPENDED':
          throw new ApiError(HttpStatus.FORBIDDEN, 'ACCOUNT_SUSPENDED', 'Account is suspended');
      }
    }
    return outcome;
  }
}
