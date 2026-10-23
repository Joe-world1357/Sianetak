import { Module } from '@nestjs/common';
import { MulterModule } from '@nestjs/platform-express';
import { TypeOrmModule } from '@nestjs/typeorm';
import { APP_CONFIG, AppConfig } from '../config/env.validation';
import { MediaController } from './media.controller';
import { mediaStorageProvider } from './media-storage';
import { MediaFile } from './media.entity';
import { MediaService } from './media.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([MediaFile]),
    // No `dest`/`storage`: multer keeps the upload in memory, under hard limits, so nothing
    // touches disk until the bytes have been validated.
    MulterModule.registerAsync({
      inject: [APP_CONFIG],
      useFactory: (config: AppConfig) => ({
        limits: {
          fileSize: Math.max(config.media.maxImageBytes, config.media.maxDocumentBytes),
          files: 1,
          fields: 2,
          parts: 3,
          fieldSize: 1024,
        },
      }),
    }),
  ],
  controllers: [MediaController],
  providers: [MediaService, mediaStorageProvider],
  exports: [MediaService],
})
export class MediaModule {}
