import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';

const REQUEST_ID_PATTERN = /^[A-Za-z0-9-]{8,64}$/;

/**
 * Assigns a request id and writes one access-log line per request.
 * Logs method, route path, status and duration only — never headers, query strings or bodies,
 * which may carry tokens, phone numbers or OTP codes.
 */
@Injectable()
export class RequestLoggingMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request & { requestId?: string }, res: Response, next: NextFunction) {
    const incoming = req.header('x-request-id');
    const requestId = incoming && REQUEST_ID_PATTERN.test(incoming) ? incoming : randomUUID();
    req.requestId = requestId;
    res.setHeader('x-request-id', requestId);

    const started = process.hrtime.bigint();
    res.on('finish', () => {
      const ms = Number(process.hrtime.bigint() - started) / 1e6;
      this.logger.log(
        `${req.method} ${req.path} ${res.statusCode} ${ms.toFixed(1)}ms [${requestId}]`,
      );
    });
    next();
  }
}
