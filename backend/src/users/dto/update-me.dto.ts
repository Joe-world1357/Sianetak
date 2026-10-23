import { Transform } from 'class-transformer';
import { IsString, Length, Matches } from 'class-validator';

export class UpdateMeDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value))
  @IsString()
  @Length(2, 80)
  // Letters (any script), spaces, apostrophes, dots and hyphens.
  @Matches(/^[\p{L}\p{M}][\p{L}\p{M}' .-]*$/u, { message: 'name contains invalid characters' })
  name: string;
}
