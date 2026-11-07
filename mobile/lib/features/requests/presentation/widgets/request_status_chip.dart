import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/request_models.dart';

String requestStatusLabel(AppLocalizations l10n, RequestStatus status) =>
    switch (status) {
      RequestStatus.submitted => l10n.statusSubmitted,
      RequestStatus.unmatched => l10n.statusUnmatched,
      RequestStatus.assigned => l10n.statusAssigned,
      RequestStatus.enRoute => l10n.statusEnRoute,
      RequestStatus.arrived => l10n.statusArrived,
      RequestStatus.quoted => l10n.statusQuoted,
      RequestStatus.quoteRejected => l10n.statusQuoteRejected,
      RequestStatus.inProgress => l10n.statusInProgress,
      RequestStatus.completed => l10n.statusCompleted,
      RequestStatus.cancelled => l10n.statusCancelled,
      RequestStatus.unknown => l10n.statusUnknown,
    };

(Color, Color) requestStatusTone(RequestStatus status) => switch (status) {
  RequestStatus.submitted => AppColors.info,
  RequestStatus.unmatched || RequestStatus.quoteRejected => AppColors.warning,
  RequestStatus.quoted => AppColors.warning,
  RequestStatus.assigned ||
  RequestStatus.enRoute ||
  RequestStatus.arrived ||
  RequestStatus.inProgress => AppColors.progress,
  RequestStatus.completed => AppColors.success,
  RequestStatus.cancelled => AppColors.danger,
  RequestStatus.unknown => AppColors.neutral,
};

IconData requestStatusIcon(RequestStatus status) => switch (status) {
  RequestStatus.submitted => Icons.travel_explore_rounded,
  RequestStatus.unmatched => Icons.support_agent_rounded,
  RequestStatus.assigned => Icons.how_to_reg_rounded,
  RequestStatus.enRoute => Icons.directions_car_rounded,
  RequestStatus.arrived => Icons.location_on_rounded,
  RequestStatus.quoted ||
  RequestStatus.quoteRejected => Icons.request_quote_rounded,
  RequestStatus.inProgress => Icons.handyman_rounded,
  RequestStatus.completed => Icons.task_alt_rounded,
  RequestStatus.cancelled => Icons.cancel_rounded,
  RequestStatus.unknown => Icons.help_outline_rounded,
};

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) => TonePill(
    label: requestStatusLabel(AppLocalizations.of(context), status),
    tone: requestStatusTone(status),
  );
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
