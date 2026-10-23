import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/auth_error_text.dart';
import '../../application/request_draft_controller.dart';
import '../../domain/request_models.dart';

/// Step 3: "as soon as possible" or one of the slots the server offers (FR-REQ-05).
class ScheduleStep extends StatelessWidget {
  const ScheduleStep({
    super.key,
    required this.draft,
    required this.showErrors,
  });

  final RequestDraftController draft;
  final bool showErrors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final slots = draft.options.slots;
    final selected = draft.schedule;

    // Group slots by local day, keeping server order.
    final days = <List<TimeSlot>>[];
    for (final slot in slots) {
      if (days.isEmpty || !sameLocalDay(days.last.first.from, slot.from)) {
        days.add([slot]);
      } else {
        days.last.add(slot);
      }
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (draft.options.asapAvailable)
          Card(
            child: RadioGroup<bool>(
              groupValue: selected?.type == ScheduleType.asap ? true : null,
              onChanged: (_) => draft.update(
                () => draft.schedule = const RequestSchedule.asap(),
              ),
              child: RadioListTile<bool>(
                value: true,
                title: Text(l10n.scheduleAsap),
                subtitle: Text(l10n.scheduleAsapHint),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            l10n.scheduleChooseSlot,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (slots.isEmpty) Text(l10n.scheduleNoSlots),
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(
              formatDay(day.first.from, lang),
              style: theme.textTheme.labelLarge,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final slot in day)
                ChoiceChip(
                  label: Text(
                    '${formatTime(slot.from, lang)} – ${formatTime(slot.to, lang)}',
                  ),
                  selected: selected?.slot == slot,
                  onSelected: (_) => draft.update(
                    () => draft.schedule = RequestSchedule.slot(slot),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showErrors && draft.scheduleIssue() != null)
          AuthErrorText(l10n.scheduleMissing),
      ],
    );
  }
}
