import { UserRole, UserStatus } from '../users/user.entity';
import { VerificationStatus as S } from './technician.entities';
import { isEligibleTechnician, reviewTransition, submitOutcome } from './technician.rules';

describe('reviewTransition', () => {
  it.each([
    ['approve', S.PendingReview, S.Approved],
    ['reject', S.PendingReview, S.Rejected],
    ['suspend', S.Approved, S.Suspended],
    ['approve', S.Suspended, S.Approved],
  ] as const)('%s from %s leads to %s', (decision, from, to) => {
    expect(reviewTransition(decision, from)?.to).toBe(to);
  });

  it.each([
    ['approve', S.Approved],
    ['approve', S.Rejected],
    ['reject', S.Approved],
    ['reject', S.Rejected],
    ['suspend', S.PendingReview],
    ['suspend', S.Suspended],
  ] as const)('refuses %s from %s', (decision, from) => {
    expect(reviewTransition(decision, from)).toBeNull();
  });

  it('requires a reason to reject or suspend', () => {
    expect(reviewTransition('reject', S.PendingReview)?.reasonRequired).toBe(true);
    expect(reviewTransition('suspend', S.Approved)?.reasonRequired).toBe(true);
    expect(reviewTransition('approve', S.PendingReview)?.reasonRequired).toBe(false);
  });
});

describe('submitOutcome', () => {
  it('creates a first application', () => {
    expect(submitOutcome(null, 'h', true)).toBe('create');
  });

  it('replays an identical pending submission and refuses a different one', () => {
    const pending = { status: S.PendingReview, submissionHash: 'h' };
    expect(submitOutcome(pending, 'h', true)).toBe('replay');
    expect(submitOutcome(pending, 'other', true)).toBe('already_submitted');
  });

  it('allows resubmission after rejection only when configured', () => {
    const rejected = { status: S.Rejected, submissionHash: 'h' };
    expect(submitOutcome(rejected, 'x', true)).toBe('resubmit');
    expect(submitOutcome(rejected, 'x', false)).toBe('locked');
  });

  it.each([S.Approved, S.Suspended])('locks a %s application', (status) => {
    expect(submitOutcome({ status, submissionHash: 'h' }, 'x', true)).toBe('locked');
  });
});

describe('isEligibleTechnician', () => {
  const tech = { role: UserRole.Technician, status: UserStatus.Active };

  it('is true only for an active technician with an approved application', () => {
    expect(isEligibleTechnician(tech, { status: S.Approved })).toBe(true);
  });

  it.each([S.PendingReview, S.Rejected, S.Suspended])('is false while %s', (status) => {
    expect(isEligibleTechnician(tech, { status })).toBe(false);
  });

  it('is false without an application, for other roles, or for suspended accounts', () => {
    expect(isEligibleTechnician(tech, null)).toBe(false);
    expect(isEligibleTechnician({ ...tech, role: UserRole.Customer }, { status: S.Approved })).toBe(
      false,
    );
    expect(
      isEligibleTechnician({ ...tech, status: UserStatus.Suspended }, { status: S.Approved }),
    ).toBe(false);
  });
});
