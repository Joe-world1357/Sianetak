import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { User } from '../../users/user.entity';

/** The authenticated user, loaded from the database by JwtAuthGuard. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): User => ctx.switchToHttp().getRequest().user,
);
