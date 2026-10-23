import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { throttlerOptions } from './auth/throttle';
import { CatalogModule } from './catalog/catalog.module';
import { RequestLoggingMiddleware } from './common/http/request-logging.middleware';
import { AppConfigModule } from './config/config.module';
import { APP_CONFIG } from './config/env.validation';
import { typeormOptions } from './database/typeorm-options';
import { HealthController } from './health/health.controller';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    AppConfigModule,
    TypeOrmModule.forRootAsync({ inject: [APP_CONFIG], useFactory: typeormOptions }),
    ThrottlerModule.forRootAsync({ inject: [APP_CONFIG], useFactory: throttlerOptions }),
    UsersModule,
    AuthModule,
    CatalogModule,
  ],
  controllers: [HealthController],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestLoggingMiddleware).forRoutes('{*splat}');
  }
}
