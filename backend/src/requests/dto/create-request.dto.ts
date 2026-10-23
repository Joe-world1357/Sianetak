import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDefined,
  IsEnum,
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { AddressInputDto } from '../../locations/dto/address.dto';
import { ScheduleType } from '../request.entities';
import { DESCRIPTION_MAX_LENGTH, DESCRIPTION_MIN_LENGTH } from '../request.rules';

export class ScheduleDto {
  @IsEnum(ScheduleType)
  type: ScheduleType;

  /** Required for `scheduled`: one of the slots offered by GET /requests/options. */
  @ValidateIf((o: ScheduleDto) => o.type === ScheduleType.Scheduled)
  @IsISO8601({ strict: true })
  from?: string;

  @ValidateIf((o: ScheduleDto) => o.type === ScheduleType.Scheduled)
  @IsISO8601({ strict: true })
  to?: string;
}

export class CreateRequestDto {
  @IsUUID()
  serviceId: string;

  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(DESCRIPTION_MIN_LENGTH, DESCRIPTION_MAX_LENGTH)
  description: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsUUID(undefined, { each: true })
  photoIds?: string[];

  /** Either a saved address id… */
  @IsOptional()
  @IsUUID()
  addressId?: string;

  /** …or a newly typed address, optionally saved for next time. */
  @IsOptional()
  @ValidateNested()
  @Type(() => AddressInputDto)
  address?: AddressInputDto;

  @IsOptional()
  @IsBoolean()
  saveAddress?: boolean;

  @IsDefined()
  @ValidateNested()
  @Type(() => ScheduleDto)
  schedule: ScheduleDto;
}
