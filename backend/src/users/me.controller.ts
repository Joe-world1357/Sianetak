import { Body, Controller, Get, Patch } from '@nestjs/common';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { UpdateMeDto } from './dto/update-me.dto';
import type { User } from './user.entity';
import { presentMe } from './user.presenter';
import { UsersService } from './users.service';

/** Profile foundation for any signed-in role (authentication enforced by the global guard). */
@Controller('me')
export class MeController {
  constructor(private readonly users: UsersService) {}

  @Get()
  me(@CurrentUser() user: User) {
    return presentMe(user);
  }

  @Patch()
  async update(@CurrentUser() user: User, @Body() dto: UpdateMeDto) {
    return presentMe(await this.users.updateName(user, dto.name));
  }
}
