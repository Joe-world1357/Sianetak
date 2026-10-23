import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { ApiError } from '../common/errors/api-error';
import type { User } from '../users/user.entity';
import { TechniciansService } from './technicians.service';

/**
 * Route guard for anything that exposes or assigns work to technicians (FR-AUTH-07). Use with
 * `@UseGuards(ApprovedTechnicianGuard)` after authentication. Pending, rejected and suspended
 * technicians are refused with TECHNICIAN_NOT_ELIGIBLE. Sprint 3 dispatch endpoints rely on it.
 */
@Injectable()
export class ApprovedTechnicianGuard implements CanActivate {
  constructor(private readonly technicians: TechniciansService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const user: User | undefined = context.switchToHttp().getRequest().user;
    if (!user || !(await this.technicians.isEligible(user))) {
      throw new ApiError(
        HttpStatus.FORBIDDEN,
        'TECHNICIAN_NOT_ELIGIBLE',
        'Only approved technicians can access work',
      );
    }
    return true;
  }
}
