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
  | 'IDEMPOTENCY_KEY_REQUIRED'
  | 'IDEMPOTENCY_KEY_REUSED'
  | 'SERVICE_NOT_AVAILABLE'
  | 'AREA_NOT_AVAILABLE'
  | 'ADDRESS_NOT_FOUND'
  | 'ADDRESS_LIMIT_REACHED'
  | 'LOCATION_REQUIRED'
  | 'LOCATION_OUT_OF_AREA'
  | 'INVALID_SCHEDULE'
  | 'TOO_MANY_OPEN_REQUESTS'
  | 'REQUEST_NOT_FOUND'
  | 'MEDIA_NOT_FOUND'
  | 'MEDIA_INVALID'
  | 'MEDIA_TOO_MANY'
  | 'MEDIA_PENDING_LIMIT'
  | 'FILE_REQUIRED'
  | 'FILE_TOO_LARGE'
  | 'UNSUPPORTED_FILE_TYPE'
  | 'MEDIA_STORAGE_UNAVAILABLE'
  | 'APPLICATION_NOT_FOUND'
  | 'APPLICATION_ALREADY_SUBMITTED'
  | 'APPLICATION_STATE_CONFLICT'
  | 'APPLICATION_NOT_ALLOWED'
  | 'CANNOT_REVIEW_OWN_APPLICATION'
  | 'CATEGORY_NOT_AVAILABLE'
  | 'DOCUMENTS_REQUIRED'
  | 'TECHNICIAN_NOT_ELIGIBLE'
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
