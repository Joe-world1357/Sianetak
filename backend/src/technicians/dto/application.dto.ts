import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import { DocumentKind, VerificationStatus } from '../technician.entities';

const collapse = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;

export class ApplicationDocumentDto {
  @IsUUID()
  mediaId: string;

  @IsEnum(DocumentKind)
  kind: DocumentKind;
}

export class SubmitApplicationDto {
  @Transform(collapse)
  @IsString()
  @Length(2, 80)
  @Matches(/^[\p{L}\p{M}][\p{L}\p{M}' .-]*$/u, { message: 'fullName contains invalid characters' })
  fullName: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(60)
  yearsOfExperience?: number;

  @Transform(({ value }) => {
    const v = typeof value === 'string' ? value.trim() : value;
    return v === '' ? undefined : v;
  })
  @IsOptional()
  @IsString()
  @Length(1, 1000)
  bio?: string;

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(10)
  @ArrayUnique()
  @IsUUID(undefined, { each: true })
  specialtyCategoryIds: string[];

  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(20)
  @ArrayUnique()
  @IsUUID(undefined, { each: true })
  serviceAreaIds: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => ApplicationDocumentDto)
  documents?: ApplicationDocumentDto[];
}

export class ApproveApplicationDto {
  @Transform(collapse)
  @IsOptional()
  @IsString()
  @Length(3, 500)
  note?: string;
}

export class DecisionReasonDto {
  @Transform(collapse)
  @IsString()
  @Length(3, 500)
  reason: string;
}

export class ListApplicationsDto {
  @IsOptional()
  @IsEnum(VerificationStatus)
  status?: VerificationStatus;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(100000)
  offset?: number;
}
