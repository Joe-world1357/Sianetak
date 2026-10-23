import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { ApiError } from '../../common/errors/api-error';
import type { User, UserRole } from '../../users/user.entity';
import { ROLES_KEY } from '../decorators/roles.decorator';

/** Global guard (runs after JwtAuthGuard): enforces @Roles() using the role stored in the DB. */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<UserRole[] | undefined>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;

    const user: User | undefined = context.switchToHttp().getRequest().user;
    if (!user || !required.includes(user.role)) {
      throw new ApiError(HttpStatus.FORBIDDEN, 'FORBIDDEN', 'Insufficient role for this action');
    }
    return true;
  }
}
