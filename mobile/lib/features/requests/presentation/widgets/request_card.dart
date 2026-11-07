import 'package:flutter/material.dart';

import '../../../../core/format/dates.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/egypt_phone.dart';
import '../../domain/request_models.dart';
import '../request_detail_screen.dart';
import 'request_status_chip.dart';

/// A request in a list: service, status, reference, area and timing. Opens the detail.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    this.footer,
    this.onTap,
  });

  final RequestSummary request;

  /// Extra content under the summary (offer deadline, quick actions).
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => RequestDetailScreen(requestId: request.id),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(
                    icon: requestStatusIcon(request.status),
                    tone: requestStatusTone(request.status),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                request.service.name.resolve(lang),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            RequestStatusChip(status: request.status),
                          ],
                        ),
                        Text(
                          '${l10n.requestReferenceLabel}: ${isolateLtr(request.reference)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + 4),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      request.area.name.resolve(lang),
                      style: muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const ExcludeSemantics(
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scheduleLabel(l10n, request.schedule, lang),
                      style: muted,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                l10n.submittedOn(formatDateTime(request.submittedAt, lang)),
                style: muted,
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.md),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
