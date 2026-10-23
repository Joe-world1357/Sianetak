import { INestApplication, ValidationPipe } from '@nestjs/common';
import { HttpExceptionFilter } from './common/errors/http-exception.filter';
import { APP_CONFIG, AppConfig } from './config/env.validation';

export const API_PREFIX = 'api/v1';

/** Shared HTTP setup for the server and the integration tests. */
export function setupApp(app: INestApplication) {
  const config = app.get<AppConfig>(APP_CONFIG);
  app.setGlobalPrefix(API_PREFIX);
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      stopAtFirstError: false,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.enableCors({
    origin: config.corsOrigins.length > 0 ? config.corsOrigins : false,
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Authorization', 'Content-Type', 'X-Request-Id', 'Accept-Language'],
    exposedHeaders: ['X-Request-Id'],
  });
  const http = app.getHttpAdapter().getInstance();
  http.disable?.('x-powered-by');
  // Behind a reverse proxy, trust only the first hop for client IPs (rate limiting).
  http.set?.('trust proxy', 1);
  return config;
}
