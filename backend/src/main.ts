import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { API_PREFIX, setupApp } from './app.setup';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger:
      process.env.NODE_ENV === 'production'
        ? ['log', 'warn', 'error']
        : ['log', 'warn', 'error', 'debug'],
  });
  const config = setupApp(app);
  app.enableShutdownHooks();
  await app.listen(config.port);
  new Logger('Bootstrap').log(
    `Sianetak API (${config.nodeEnv}) on :${config.port}/${API_PREFIX} — OTP provider: ${config.otp.provider}`,
  );
}

bootstrap().catch((err) => {
  // Config errors list variable names only, never values.
  new Logger('Bootstrap').error((err as Error).message);
  process.exit(1);
});
