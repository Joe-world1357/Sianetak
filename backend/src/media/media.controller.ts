import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  StreamableFile,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { IsEnum } from 'class-validator';
import type { Response } from 'express';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { ApiError } from '../common/errors/api-error';
import type { User } from '../users/user.entity';
import { MediaPurpose } from './media.entity';
import { MediaService } from './media.service';

class UploadMediaDto {
  @IsEnum(MediaPurpose)
  purpose: MediaPurpose;
}

const notFound = () => new ApiError(HttpStatus.NOT_FOUND, 'MEDIA_NOT_FOUND', 'File not found');

/** Private uploads: request photos (FR-REQ-03) and technician documents (FR-AUTH-06). */
@Controller('media')
export class MediaController {
  constructor(private readonly media: MediaService) {}

  /** multipart/form-data with `purpose` and a single `file`. */
  @Post()
  @UseInterceptors(FileInterceptor('file'))
  upload(
    @CurrentUser() user: User,
    @Body() dto: UploadMediaDto,
    @UploadedFile() file: Express.Multer.File | undefined,
  ) {
    return this.media.upload(user, dto.purpose, file);
  }

  @Get(':id/content')
  async content(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ exceptionFactory: notFound })) id: string,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { media, data } = await this.media.readContent(user, id);
    res.set({
      'Content-Type': media.contentType,
      'Cache-Control': 'private, no-store',
      'X-Content-Type-Options': 'nosniff',
      'Content-Security-Policy': "default-src 'none'; sandbox",
      'Content-Disposition':
        media.contentType === 'application/pdf'
          ? `attachment; filename="${media.id}.pdf"`
          : 'inline',
    });
    return new StreamableFile(data);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(
    @CurrentUser() user: User,
    @Param('id', new ParseUUIDPipe({ exceptionFactory: notFound })) id: string,
  ) {
    await this.media.removePending(user, id);
  }
}
