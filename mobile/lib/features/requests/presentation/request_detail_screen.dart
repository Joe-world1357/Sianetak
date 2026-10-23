import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/private_image.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/egypt_phone.dart';
import '../../catalog/presentation/price_guidance_text.dart';
import '../domain/request_models.dart';
import 'widgets/request_status_chip.dart';

/// A submitted request as stored on the server; visible to its owner only.
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requests = AppScope.of(context).requests;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestDetailTitle)),
      body: AsyncView<RequestDetail>(
        load: () => requests.get(requestId),
        builder: (context, detail, reload) => RefreshIndicator(
          onRefresh: reload,
          child: _Body(detail: detail),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final s = detail.summary;
    final bold = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: bold)),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  s.service.name.resolve(lang),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            RequestStatusChip(status: s.status),
          ],
        ),
        Text(
          s.service.categoryName.resolve(lang),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        SelectableText(
          '${l10n.requestReferenceLabel}: ${isolateLtr(s.reference)}',
          style: theme.textTheme.titleMedium,
        ),
        Text(
          l10n.submittedOn(formatDateTime(s.submittedAt, lang)),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        section(l10n.reviewDescriptionLabel, [Text(detail.description)]),
        section(l10n.reviewPhotosLabel, [
          if (detail.photoIds.isEmpty)
            Text(l10n.reviewNoPhotos)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final (i, id) in detail.photoIds.indexed)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    child: SizedBox.square(
                      dimension: 104,
                      child: PrivateImage(
                        mediaId: id,
                        semanticLabel: l10n.photoNumber(i + 1),
                      ),
                    ),
                  ),
              ],
            ),
        ]),
        section(l10n.reviewLocationLabel, [
          Text(
            detail.areaName.resolve(lang),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(detail.addressDetails),
          if (detail.landmark != null) Text(detail.landmark!),
          if (detail.coordinates != null)
            Text(l10n.locationCaptured, style: theme.textTheme.bodySmall),
        ]),
        section(l10n.reviewScheduleLabel, [
          Text(scheduleLabel(l10n, s.schedule, lang)),
        ]),
        section(l10n.reviewPricingLabel, [
          PriceGuidanceText(pricing: detail.pricing),
          Text(
            detail.inspectionFee == null
                ? l10n.feeNoneAtSubmission
                : l10n.feeInspection(
                    formatEgp(detail.inspectionFee!.amountMinor, lang),
                  ),
          ),
        ]),
        section(l10n.timelineTitle, [
          for (final e in detail.timeline)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_checked),
              title: Text(requestStatusLabel(l10n, e.status)),
              subtitle: Text(formatDateTime(e.at, lang)),
            ),
        ]),
      ],
    );
  }
}
