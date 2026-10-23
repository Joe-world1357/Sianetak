import 'package:flutter/material.dart';

import '../../../../core/format/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../catalog/presentation/price_guidance_text.dart';
import '../../application/request_draft_controller.dart';
import 'request_status_chip.dart';

/// Step 4: everything the customer is about to send, with the disclosed fees (FR-REQ-07).
class ReviewStep extends StatelessWidget {
  const ReviewStep({super.key, required this.draft, required this.onEdit});

  final RequestDraftController draft;
  final void Function(RequestStep step) onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final service = draft.service;
    final fee = draft.options.inspectionFee;
    final area = draft.selectedArea?.name.resolve(lang) ?? '';
    final address = draft.useNewAddress
        ? draft.details.trim()
        : draft.selectedAddress?.details ?? '';
    final landmark = draft.useNewAddress
        ? draft.landmark.trim()
        : draft.selectedAddress?.landmark ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Section(
          title: l10n.reviewServiceLabel,
          child: Text(
            '${service.summary.name.resolve(lang)} — ${service.categoryName.resolve(lang)}',
          ),
        ),
        _Section(
          title: l10n.reviewDescriptionLabel,
          onEdit: () => onEdit(RequestStep.describe),
          child: Text(draft.description.trim()),
        ),
        _Section(
          title: l10n.reviewPhotosLabel,
          onEdit: () => onEdit(RequestStep.describe),
          child: draft.photos.isEmpty
              ? Text(l10n.reviewNoPhotos)
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final (i, p) in draft.photos.indexed)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        child: Image.memory(
                          p.file.bytes,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          semanticLabel: l10n.photoNumber(i + 1),
                        ),
                      ),
                  ],
                ),
        ),
        _Section(
          title: l10n.reviewLocationLabel,
          onEdit: () => onEdit(RequestStep.location),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(area, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(address),
              if (landmark.isNotEmpty) Text(landmark),
              if (draft.useNewAddress && draft.point != null)
                Text(l10n.locationCaptured, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        _Section(
          title: l10n.reviewScheduleLabel,
          onEdit: () => onEdit(RequestStep.schedule),
          child: Text(
            draft.schedule == null
                ? ''
                : scheduleLabel(l10n, draft.schedule!, lang),
          ),
        ),
        _Section(
          title: l10n.reviewPricingLabel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceGuidanceText(pricing: service.summary.pricing),
              const SizedBox(height: AppSpacing.xs),
              Text(
                fee == null
                    ? l10n.feeNoneAtSubmission
                    : l10n.feeInspection(formatEgp(fee.amountMinor, lang)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(Icons.info_outline, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.reviewNextSteps)),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onEdit});

  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (onEdit != null)
                    TextButton(
                      onPressed: onEdit,
                      child: Semantics(
                        label: '${l10n.editButton} $title',
                        excludeSemantics: true,
                        child: Text(l10n.editButton),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
