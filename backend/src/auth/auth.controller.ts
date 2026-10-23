import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { presentMe } from '../users/user.presenter';
import { AuthService } from './auth.service';
import { Public } from './decorators/public.decorator';
import { RefreshTokenDto, RequestOtpDto, VerifyOtpDto } from './dto/auth.dto';
import { TokenService } from './token.service';
import { AuthThrottle } from './throttle';

@Controller('auth')
@Public()
export class AuthController {
  constructor(
    private readonly auth: AuthService,
    private readonly tokens: TokenService,
  ) {}

  @Post('otp/request')
  @HttpCode(HttpStatus.OK)
  @AuthThrottle()
  requestOtp(@Body() dto: RequestOtpDto) {
    return this.auth.requestOtp(dto.phone);
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  @AuthThrottle()
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    const { user, tokens, isNewUser } = await this.auth.verifyOtp(
      dto.challengeId,
      dto.phone,
      dto.code,
    );
    return { ...tokens, isNewUser, user: presentMe(user) };
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() dto: RefreshTokenDto) {
    const { user, tokens } = await this.tokens.rotate(dto.refreshToken);
    return { ...tokens, user: presentMe(user) };
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshTokenDto) {
    await this.tokens.revoke(dto.refreshToken);
  }
}
