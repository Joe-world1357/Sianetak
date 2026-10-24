import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/egypt_phone.dart';
import '../../catalog/presentation/price_guidance_text.dart';
import '../domain/request_models.dart';
import 'chat_screen.dart';
import 'widgets/journey_progress.dart';
import 'widgets/request_actions.dart';
import 'widgets/request_status_chip.dart';

/// One request and everything that happened to it, with the actions open to the viewer's
/// role (customer, assigned or offered technician, admin).
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestDetailTitle)),
      body: AsyncView<RequestDetail>(
        load: () => scope.requests.get(requestId),
        refreshOn: scope.changes,
        builder: (context, detail, reload) => RefreshIndicator(
          onRefresh: reload,
          child: _Body(
            detail: detail,
            role: scope.auth.user?.role ?? UserRole.unknown,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail, required this.role});

  final RequestDetail detail;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final s = detail.summary;
    const gap = SizedBox(height: AppSpacing.md);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _Header(detail: detail),
        gap,
        RequestActions(detail: detail, role: role),
        if (detail.technician != null && role != UserRole.technician) ...[
          _PersonCard(
            title: l10n.technicianCardTitle,
            person: detail.technician!,
            showRating: true,
            detail: detail,
            role: role,
          ),
          gap,
        ],
        if (detail.customer != null && role != UserRole.customer) ...[
          _PersonCard(
            title: l10n.customerCardTitle,
            person: detail.customer!,
            detail: detail,
            role: role,
          ),
          gap,
        ],
        if (detail.quote != null) ...[_QuoteCard(detail: detail), gap],
        if (detail.payment != null) ...[
          SectionCard(
            title: l10n.paymentTitle,
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InfoRow(
                  icon: Icons.money_rounded,
                  label: l10n.paymentCashCollected,
                  value: formatEgp(detail.payment!.amountMinor, lang),
                ),
                if (role != UserRole.customer)
                  InfoRow(
                    icon: Icons.percent_rounded,
                    label: l10n.paymentCommission,
                    value: formatEgp(detail.payment!.commissionMinor, lang),
                  ),
                InfoRow(
                  icon: Icons.event_available_rounded,
                  label: l10n.paymentRecordedAt,
                  value: formatDateTime(detail.payment!.at, lang),
                ),
              ],
            ),
          ),
          gap,
        ],
        if (detail.rating != null) ...[
          SectionCard(
            title: l10n.ratingTitle,
            icon: Icons.star_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StarRating(
                  value: detail.rating!.stars.toDouble(),
                  size: 24,
                  semanticLabel: l10n.ratingStars(detail.rating!.stars),
                ),
                if (detail.rating!.comment != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('“${detail.rating!.comment!}”'),
                ],
              ],
            ),
          ),
          gap,
        ],
        if (detail.cancelReason != null) ...[
          SectionCard(
            title: l10n.cancelReasonTitle,
            icon: Icons.info_outline_rounded,
            child: Text(detail.cancelReason!),
          ),
          gap,
        ],
        SectionCard(
          title: l10n.reviewDescriptionLabel,
          icon: Icons.notes_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(detail.description, style: theme.textTheme.bodyLarge),
              if (detail.photoIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final (i, id) in detail.photoIds.indexed)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        child: SizedBox.square(
                          dimension: 96,
                          child: PrivateImage(
                            mediaId: id,
                            semanticLabel: l10n.photoNumber(i + 1),
                          ),
                        ),
                      ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.reviewNoPhotos,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
        gap,
        SectionCard(
          title: l10n.reviewLocationLabel,
          icon: Icons.place_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.areaName.resolve(lang),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (detail.addressDetails.isNotEmpty) Text(detail.addressDetails),
              if (detail.addressDetails.isEmpty)
                Text(
                  l10n.addressHiddenUntilAccepted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              if (detail.landmark != null) Text(detail.landmark!),
              if (detail.coordinates != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: TonePill(
                    label: l10n.locationCaptured,
                    tone: AppColors.success,
                    icon: Icons.my_location_rounded,
                  ),
                ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: l10n.reviewScheduleLabel,
          icon: Icons.schedule_rounded,
          child: Text(scheduleLabel(l10n, s.schedule, lang)),
        ),
        gap,
        SectionCard(
          title: l10n.reviewPricingLabel,
          icon: Icons.sell_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PriceGuidanceText(pricing: detail.pricing),
              Text(
                detail.inspectionFee == null
                    ? l10n.feeNoneAtSubmission
                    : l10n.feeInspection(
                        formatEgp(detail.inspectionFee!.amountMinor, lang),
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        gap,
        SectionCard(
          title: l10n.timelineTitle,
          icon: Icons.timeline_rounded,
          child: _Timeline(entries: detail.timeline),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final s = detail.summary;
    final white70 = Colors.white.withValues(alpha: 0.78);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg - 4),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  s.service.categoryName.resolve(lang),
                  style: theme.textTheme.labelLarge?.copyWith(color: white70),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  requestStatusLabel(l10n, s.status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: requestStatusTone(s.status).$1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            header: true,
            child: Text(
              s.service.name.resolve(lang),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            '${l10n.requestReferenceLabel}: ${isolateLtr(s.reference)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          Text(
            l10n.submittedOn(formatDateTime(s.submittedAt, lang)),
            style: theme.textTheme.bodySmall?.copyWith(color: white70),
          ),
          if (s.status != RequestStatus.cancelled) ...[
            const SizedBox(height: AppSpacing.md),
            JourneyProgress(status: s.status, onDark: true),
          ],
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.title,
    required this.person,
    required this.detail,
    required this.role,
    this.showRating = false,
  });

  final String title;
  final PersonRef person;
  final RequestDetail detail;
  final UserRole role;
  final bool showRating;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final initial = person.name.trim().isEmpty
        ? '؟'
        : person.name.trim().characters.first;
    final status = detail.summary.status;
    final chatOpen = status.hasTechnician;
    return SectionCard(
      title: title,
      icon: Icons.person_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isolateLtr(displayLocalPhone(person.phone)),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    if (showRating)
                      Row(
                        children: [
                          StarRating(value: person.rating ?? 0, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            person.rating == null
                                ? l10n.ratingNone
                                : l10n.ratingSummary(
                                    person.rating!.toStringAsFixed(1),
                                    person.ratingCount,
                                  ),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (status == RequestStatus.enRoute && role == UserRole.customer) ...[
            const SizedBox(height: AppSpacing.md),
            TonePill(
              label: l10n.etaEstimate,
              tone: AppColors.progress,
              icon: Icons.directions_car_rounded,
            ),
          ],
          if (chatOpen) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatScreen(
                    requestId: detail.summary.id,
                    reference: detail.summary.reference,
                    readOnly: role == UserRole.admin || status.isFinal,
                  ),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(
                role == UserRole.admin
                    ? l10n.chatViewButton
                    : l10n.chatOpenButton,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.detail});

  final RequestDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final q = detail.quote!;
    final (label, tone) = switch (q.status) {
      QuoteStatus.pending => (l10n.quotePending, AppColors.warning),
      QuoteStatus.approved => (l10n.quoteApproved, AppColors.success),
      QuoteStatus.rejected => (l10n.quoteRejected, AppColors.danger),
    };
    return SectionCard(
      title: l10n.quoteTitle,
      icon: Icons.request_quote_outlined,
      trailing: TonePill(label: label, tone: tone),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatEgp(q.amountMinor, lang),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (q.note != null) Text(q.note!),
          Text(
            formatDateTime(q.at, lang),
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.entries});

  final List<RequestTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final ordered = entries.reversed.toList();
    return Column(
      children: [
        for (final (i, e) in ordered.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0
                              ? requestStatusTone(e.status).$1
                              : AppColors.line,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      if (i < ordered.length - 1)
                        Expanded(
                          child: Container(width: 2, color: AppColors.line),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          requestStatusLabel(l10n, e.status) +
                              (e.note == 'admin'
                                  ? ' · ${l10n.byOperations}'
                                  : ''),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: i == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          formatDateTime(e.at, lang),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
