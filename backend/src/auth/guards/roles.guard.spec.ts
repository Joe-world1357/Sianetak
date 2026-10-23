import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../../users/user.entity';
import { RolesGuard } from './roles.guard';

const contextFor = (user: unknown) =>
  ({
    getHandler: () => undefined,
    getClass: () => undefined,
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
  }) as unknown as ExecutionContext;

describe('RolesGuard', () => {
  const reflectorReturning = (roles?: UserRole[]) =>
    ({ getAllAndOverride: () => roles }) as unknown as Reflector;

  it('allows routes without role requirements', () => {
    expect(new RolesGuard(reflectorReturning()).canActivate(contextFor(undefined))).toBe(true);
  });

  it('allows a user with a required role', () => {
    const guard = new RolesGuard(reflectorReturning([UserRole.Admin]));
    expect(guard.canActivate(contextFor({ role: UserRole.Admin }))).toBe(true);
  });

  it.each([UserRole.Customer, UserRole.Technician])('forbids %s on admin routes', (role) => {
    const guard = new RolesGuard(reflectorReturning([UserRole.Admin]));
    expect(() => guard.canActivate(contextFor({ role }))).toThrow('Insufficient role');
  });

  it('forbids when no user is attached', () => {
    const guard = new RolesGuard(reflectorReturning([UserRole.Customer]));
    expect(() => guard.canActivate(contextFor(undefined))).toThrow();
  });
});
