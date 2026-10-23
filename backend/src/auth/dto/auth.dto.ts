import { IsString, IsUUID, Length, MaxLength } from 'class-validator';

/** Phone format is validated by the service so the client gets a specific INVALID_PHONE code. */
export class RequestOtpDto {
  @IsString()
  @MaxLength(32)
  phone: string;
}

export class VerifyOtpDto {
  @IsUUID('4')
  challengeId: string;

  @IsString()
  @MaxLength(32)
  phone: string;

  @IsString()
  @Length(4, 16)
  code: string;
}

export class RefreshTokenDto {
  @IsString()
  @Length(20, 200)
  refreshToken: string;
}
