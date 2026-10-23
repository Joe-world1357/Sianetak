import 'package:flutter/material.dart';

import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/technician_models.dart';

String verificationStatusLabel(AppLocalizations l10n, VerificationStatus s) =>
    switch (s) {
      VerificationStatus.pendingReview => l10n.verificationPending,
      VerificationStatus.approved => l10n.verificationApproved,
      VerificationStatus.rejected => l10n.verificationRejected,
      VerificationStatus.suspended => l10n.verificationSuspended,
      VerificationStatus.unknown => l10n.statusUnknown,
    };

String documentKindLabel(AppLocalizations l10n, DocumentKind kind) =>
    switch (kind) {
      DocumentKind.identity => l10n.documentKindIdentity,
      DocumentKind.qualification => l10n.documentKindQualification,
      DocumentKind.other => l10n.documentKindOther,
    };

IconData verificationStatusIcon(VerificationStatus s) => switch (s) {
  VerificationStatus.pendingReview => Icons.hourglass_top_rounded,
  VerificationStatus.approved => Icons.verified_rounded,
  VerificationStatus.rejected => Icons.cancel_outlined,
  VerificationStatus.suspended => Icons.pause_circle_outline,
  VerificationStatus.unknown => Icons.help_outline,
};

/// The applicant's view of their verification status, with the reviewer's reason when one
/// applies and a way to resubmit after a rejection.
class VerificationStatusView extends StatelessWidget {
  const VerificationStatusView({
    super.key,
    required this.application,
    required this.onResubmit,
    required this.onRefresh,
  });

  final TechnicianApplication application;
  final VoidCallback onResubmit;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final a = application;
    final body = switch (a.status) {
      VerificationStatus.pendingReview => l10n.verificationPendingBody,
      VerificationStatus.approved => l10n.verificationApprovedBody,
      VerificationStatus.rejected =>
        a.canResubmit
            ? l10n.verificationRejectedBody
            : l10n.verificationRejectedFinal,
      VerificationStatus.suspended => l10n.verificationSuspendedBody,
      VerificationStatus.unknown => '',
    };
    final isProblem =
        a.status == VerificationStatus.rejected ||
        a.status == VerificationStatus.suspended;
    final color = isProblem ? theme.colorScheme.error : AppColors.primary;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          verificationStatusIcon(a.status),
                          color: color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Semantics(
                          header: true,
                          liveRegion: true,
                          child: Text(
                            verificationStatusLabel(l10n, a.status),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(body, style: theme.textTheme.bodyLarge),
                  if (a.decisionReason != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.decisionReasonLabel,
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(a.decisionReason!, style: theme.textTheme.bodyLarge),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.submittedOn(formatDateTime(a.submittedAt, lang)),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(a.fullName, style: theme.textTheme.titleMedium),
          if (a.yearsOfExperience != null)
            Text(l10n.yearsValue(a.yearsOfExperience!)),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.specialtiesTitle, style: theme.textTheme.labelLarge),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final s in a.specialties)
                Chip(label: Text(s.name.resolve(lang))),
            ],
          ),
          Text(l10n.serviceAreasTitle, style: theme.textTheme.labelLarge),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              for (final area in a.serviceAreas)
                Chip(label: Text(area.name.resolve(lang))),
            ],
          ),
          Text(
            '${l10n.documentsTitle}: ${a.documents.length}',
            style: theme.textTheme.labelLarge,
          ),
          if (a.status == VerificationStatus.rejected && a.canResubmit) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: onResubmit,
              child: Text(l10n.resubmitApplicationButton),
            ),
          ],
        ],
      ),
    );
  }
}
