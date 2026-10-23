import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/request_models.dart';

String requestStatusLabel(AppLocalizations l10n, RequestStatus status) =>
    switch (status) {
      RequestStatus.submitted => l10n.statusSubmitted,
      RequestStatus.unknown => l10n.statusUnknown,
    };

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        requestStatusLabel(l10n, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "As soon as possible" or the local day and time window.
String scheduleLabel(
  AppLocalizations l10n,
  RequestSchedule schedule,
  String lang,
) => schedule.slot == null
    ? l10n.scheduleAsap
    : slotLabel(l10n, schedule.slot!, lang);

String slotLabel(AppLocalizations l10n, TimeSlot slot, String lang) =>
    l10n.slotRange(
      formatDay(slot.from, lang),
      formatTime(slot.from, lang),
      formatTime(slot.to, lang),
    );
