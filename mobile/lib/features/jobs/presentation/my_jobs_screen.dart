import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../requests/domain/request_models.dart';
import '../../requests/presentation/widgets/request_card.dart';
import '../domain/job_models.dart';

/// The technician's assigned jobs (active and finished) and closeout totals.
class MyJobsScreen extends StatefulWidget {
  const MyJobsScreen({super.key});

  @override
  State<MyJobsScreen> createState() => _MyJobsScreenState();
}

class _MyJobsScreenState extends State<MyJobsScreen> {
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myJobsTitle)),
      body: AsyncView<(List<RequestSummary>, Earnings)>(
        key: ValueKey(_active),
        load: () async => (
          await scope.jobs.jobs(active: _active),
          await scope.jobs.earnings(),
        ),
        refreshOn: scope.changes,
        builder: (context, data, reload) {
          final (jobs, earnings) = data;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _EarningsCard(earnings: earnings),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.jobsActiveTab),
                      icon: const Icon(Icons.bolt_rounded),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.jobsHistoryTab),
                      icon: const Icon(Icons.history_rounded),
                    ),
                  ],
                  selected: {_active},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _active = s.first),
                ),
                const SizedBox(height: AppSpacing.md),
                if (jobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyView(
                      message: _active
                          ? l10n.jobsEmptyActive
                          : l10n.jobsEmptyHistory,
                      icon: Icons.work_outline_rounded,
                    ),
                  )
                else
                  for (final job in jobs) ...[
                    RequestCard(request: job),
                    const SizedBox(height: AppSpacing.sm + 4),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.earnings});

  final Earnings earnings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final white70 = Colors.white.withValues(alpha: 0.78);
    Widget stat(String label, String value) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: white70),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
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
            children: [
              Expanded(
                child: Text(
                  l10n.earningsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(color: white70),
                ),
              ),
              if (earnings.rating != null)
                TonePill(
                  label:
                      '${earnings.rating!.toStringAsFixed(1)} ★ (${earnings.ratingCount})',
                  tone: (AppColors.primary, Colors.white),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatEgp(earnings.netMinor, lang),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            l10n.earningsNetHint,
            style: theme.textTheme.bodySmall?.copyWith(color: white70),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              stat(l10n.earningsJobs, formatCount(earnings.jobs, lang)),
              stat(
                l10n.earningsCollected,
                formatEgp(earnings.collectedMinor, lang),
              ),
              stat(
                l10n.earningsCommission,
                formatEgp(earnings.commissionMinor, lang),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
