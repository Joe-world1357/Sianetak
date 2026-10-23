import { Logger } from '@nestjs/common';
import type { Logger as TypeOrmLogger } from 'typeorm';

/**
 * TypeORM's built-in logger prints query parameters on failure, which would leak phone numbers,
 * OTP hashes and token hashes. This logger reports failing SQL without parameters.
 */
export class SafeTypeOrmLogger implements TypeOrmLogger {
  private readonly logger = new Logger('Database');

  constructor(private readonly verbose = false) {}

  logQueryError(error: string | Error, query: string) {
    const message = typeof error === 'string' ? error : error.message;
    this.logger.error(`Query failed: ${message} — ${query.slice(0, 200)}`);
  }
  logQuerySlow(time: number, query: string) {
    this.logger.warn(`Slow query (${time}ms): ${query.slice(0, 200)}`);
  }
  logMigration(message: string) {
    this.logger.log(message);
  }
  logSchemaBuild(message: string) {
    if (this.verbose) this.logger.debug(message);
  }
  logQuery() {
    // Individual queries are not logged.
  }
  log(level: 'log' | 'info' | 'warn', message: unknown) {
    if (level === 'warn') this.logger.warn(String(message));
    else if (this.verbose) this.logger.log(String(message));
  }
}
