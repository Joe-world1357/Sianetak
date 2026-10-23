/** Pure verification rules: who may apply, allowed review transitions, and work eligibility. */
import { User, UserRole, UserStatus } from '../users/user.entity';
import { VerificationStatus } from './technician.entities';

export type ReviewDecision = 'approve' | 'reject' | 'suspend';

interface Transition {
  from: VerificationStatus[];
  to: VerificationStatus;
  reasonRequired: boolean;
}

/**
 * Approve also reinstates a suspended technician. Rejection and suspension always carry a
 * reason. Appeal and re-verification policy (SRS §8 item 10) is not approved yet.
 */
export const REVIEW_TRANSITIONS: Record<ReviewDecision, Transition> = {
  approve: {
    from: [VerificationStatus.PendingReview, VerificationStatus.Suspended],
    to: VerificationStatus.Approved,
    reasonRequired: false,
  },
  reject: {
    from: [VerificationStatus.PendingReview],
    to: VerificationStatus.Rejected,
    reasonRequired: true,
  },
  suspend: {
    from: [VerificationStatus.Approved],
    to: VerificationStatus.Suspended,
    reasonRequired: true,
  },
};

export function reviewTransition(decision: ReviewDecision, current: VerificationStatus) {
  const t = REVIEW_TRANSITIONS[decision];
  return t.from.includes(current) ? t : null;
}

/** Roles that may apply. Admin accounts never apply, which also keeps reviewers independent. */
export const APPLICANT_ROLES = [UserRole.Customer, UserRole.Technician];

export type SubmitOutcome = 'create' | 'resubmit' | 'replay' | 'already_submitted' | 'locked';

/** What an applicant's submission does, given their current application (if any). */
export function submitOutcome(
  current: { status: VerificationStatus; submissionHash: string } | null,
  hash: string,
  allowResubmitAfterRejection: boolean,
): SubmitOutcome {
  if (!current) return 'create';
  switch (current.status) {
    case VerificationStatus.PendingReview:
      return current.submissionHash === hash ? 'replay' : 'already_submitted';
    case VerificationStatus.Rejected:
      return allowResubmitAfterRejection ? 'resubmit' : 'locked';
    default:
      return 'locked';
  }
}

/**
 * The single rule for provider eligibility (FR-AUTH-07): an active account with the
 * technician role and an approved application. Use it wherever technicians can see or take work.
 */
export function isEligibleTechnician(
  user: Pick<User, 'role' | 'status'>,
  profile: { status: VerificationStatus } | null,
) {
  return (
    user.status === UserStatus.Active &&
    user.role === UserRole.Technician &&
    profile?.status === VerificationStatus.Approved
  );
}
