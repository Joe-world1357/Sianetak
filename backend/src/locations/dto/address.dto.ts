import { Transform } from 'class-transformer';
import { IsLatitude, IsLongitude, IsOptional, IsString, IsUUID, Length } from 'class-validator';

const collapse = ({ value }: { value: unknown }) =>
  typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : value;
const optionalText = ({ value }: { value: unknown }) => {
  const v = collapse({ value });
  return v === '' ? undefined : v;
};

/** A service address typed by the customer. Coordinates are optional and come as a pair. */
export class AddressInputDto {
  @Transform(optionalText)
  @IsOptional()
  @IsString()
  @Length(1, 40)
  label?: string;

  @IsUUID()
  areaId: string;

  /** Street, building, floor and apartment as the customer would tell a visitor. */
  @Transform(collapse)
  @IsString()
  @Length(5, 300)
  details: string;

  @Transform(optionalText)
  @IsOptional()
  @IsString()
  @Length(1, 150)
  landmark?: string;

  @IsOptional()
  @IsLatitude()
  latitude?: number;

  @IsOptional()
  @IsLongitude()
  longitude?: number;
}
