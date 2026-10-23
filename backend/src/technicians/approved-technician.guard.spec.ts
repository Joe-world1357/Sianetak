import { ExecutionContext } from '@nestjs/common';
import { ApprovedTechnicianGuard } from './approved-technician.guard';
import type { TechniciansService } from './technicians.service';

const contextFor = (user: unknown) =>
  ({ switchToHttp: () => ({ getRequest: () => ({ user }) }) }) as unknown as ExecutionContext;

describe('ApprovedTechnicianGuard', () => {
  const guardWith = (eligible: boolean) =>
    new ApprovedTechnicianGuard({
      isEligible: async () => eligible,
    } as unknown as TechniciansService);

  it('lets an eligible technician through', async () => {
    await expect(guardWith(true).canActivate(contextFor({ id: 'u' }))).resolves.toBe(true);
  });

  it('refuses ineligible technicians with TECHNICIAN_NOT_ELIGIBLE', async () => {
    await expect(guardWith(false).canActivate(contextFor({ id: 'u' }))).rejects.toMatchObject({
      code: 'TECHNICIAN_NOT_ELIGIBLE',
    });
  });

  it('refuses when no user is attached', async () => {
    await expect(guardWith(true).canActivate(contextFor(undefined))).rejects.toMatchObject({
      code: 'TECHNICIAN_NOT_ELIGIBLE',
    });
  });
});
