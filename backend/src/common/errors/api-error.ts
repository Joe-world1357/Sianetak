import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * Stable, machine-readable error codes. Clients map these to localized (Arabic/English) copy;
 * the `message` field is an English developer hint only.
 */
export type ErrorCode =
  | 'VALIDATION_FAILED'
  | 'INVALID_PHONE'
  | 'UNAUTHENTICATED'
  | 'FORBIDDEN'
  | 'ACCOUNT_SUSPENDED'
  | 'NOT_FOUND'
  | 'CATEGORY_NOT_FOUND'
  | 'SERVICE_NOT_FOUND'
  | 'OTP_RESEND_TOO_SOON'
  | 'OTP_RATE_LIMITED'
  | 'OTP_INVALID'
  | 'OTP_EXPIRED'
  | 'OTP_TOO_MANY_ATTEMPTS'
  | 'OTP_DELIVERY_UNAVAILABLE'
  | 'OTP_DELIVERY_FAILED'
  | 'REFRESH_TOKEN_INVALID'
  | 'RATE_LIMITED'
  | 'SERVICE_UNAVAILABLE'
  | 'INTERNAL_ERROR';

export interface ApiErrorBody {
  error: {
    code: ErrorCode;
    message: string;
    details?: Record<string, unknown>;
  };
  requestId?: string;
}

export class ApiError extends HttpException {
  constructor(
    status: HttpStatus,
    readonly code: ErrorCode,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super({ code, message, details }, status);
  }
}
