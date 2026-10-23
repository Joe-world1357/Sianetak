import { HttpStatus, Injectable, PipeTransform } from '@nestjs/common';
import { ApiError } from '../common/errors/api-error';

const SLUG = /^[a-z0-9]+(-[a-z0-9]+)*$/;

@Injectable()
export class SlugPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    if (typeof value !== 'string' || value.length > 64 || !SLUG.test(value)) {
      throw new ApiError(HttpStatus.NOT_FOUND, 'NOT_FOUND', 'Not found');
    }
    return value;
  }
}
