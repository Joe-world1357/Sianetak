import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class ListRequestsDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  /** Opaque cursor from a previous page's `nextCursor`. */
  @IsOptional()
  @IsString()
  @MaxLength(200)
  cursor?: string;
}
