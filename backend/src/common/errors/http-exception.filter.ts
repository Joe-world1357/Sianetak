import {
  ArgumentsHost,
  BadRequestException,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ThrottlerException } from '@nestjs/throttler';
import type { Request, Response } from 'express';
import { ApiError, ApiErrorBody, ErrorCode } from './api-error';

const STATUS_CODES: Partial<Record<number, ErrorCode>> = {
  400: 'VALIDATION_FAILED',
  401: 'UNAUTHENTICATED',
  403: 'FORBIDDEN',
  404: 'NOT_FOUND',
  413: 'FILE_TOO_LARGE',
  429: 'RATE_LIMITED',
  503: 'SERVICE_UNAVAILABLE',
};

/** Converts every error into the consistent `{ error: { code, message, details }, requestId }` shape. */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('HttpExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request & { requestId?: string }>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let body: ApiErrorBody['error'] = { code: 'INTERNAL_ERROR', message: 'Unexpected error' };

    if (exception instanceof ApiError) {
      status = exception.getStatus();
      body = { code: exception.code, message: exception.message, details: exception.details };
    } else if (exception instanceof ThrottlerException) {
      status = HttpStatus.TOO_MANY_REQUESTS;
      body = { code: 'RATE_LIMITED', message: 'Too many requests, try again later' };
    } else if (exception instanceof BadRequestException) {
      status = exception.getStatus();
      const response = exception.getResponse() as { message?: unknown };
      const messages = Array.isArray(response.message) ? response.message : [exception.message];
      body = {
        code: 'VALIDATION_FAILED',
        message: 'Request validation failed',
        details: { fields: messages },
      };
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      body = { code: STATUS_CODES[status] ?? 'INTERNAL_ERROR', message: exception.message };
    } else {
      // Log the error type and stack only; request bodies (phone numbers, codes) are never logged.
      const err = exception as Error;
      this.logger.error(
        `Unhandled ${err?.name ?? 'error'} on ${req.method} ${req.path} [${req.requestId}]`,
        err?.stack,
      );
    }

    res.status(status).json({ error: body, requestId: req.requestId } satisfies ApiErrorBody);
  }
}
