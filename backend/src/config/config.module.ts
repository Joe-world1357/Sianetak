import { Global, Module } from '@nestjs/common';
import { APP_CONFIG, AppConfig, validateEnv } from './env.validation';

/** Loads `.env` (if present, never in production) and exposes the validated AppConfig. */
export function loadConfig(): AppConfig {
  if (process.env.NODE_ENV !== 'production') {
    try {
      process.loadEnvFile?.('.env');
    } catch {
      // No .env file: rely on the process environment.
    }
  }
  return validateEnv(process.env);
}

@Global()
@Module({
  providers: [{ provide: APP_CONFIG, useFactory: loadConfig }],
  exports: [APP_CONFIG],
})
export class AppConfigModule {}
