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
import '../data/admin_repository.dart';

enum _Filter { attention, active, done, all }

/// Operations overview: key counts and every request, with the ones needing a person first.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _Filter _filter = _Filter.attention;

  static const _attention = {RequestStatus.unmatched, RequestStatus.submitted};
  static const _active = {
    RequestStatus.assigned,
    RequestStatus.enRoute,
    RequestStatus.arrived,
    RequestStatus.quoted,
    RequestStatus.quoteRejected,
    RequestStatus.inProgress,
  };
  static const _done = {RequestStatus.completed, RequestStatus.cancelled};

  Set<RequestStatus> get _statuses => switch (_filter) {
    _Filter.attention => _attention,
    _Filter.active => _active,
    _Filter.done => _done,
    _Filter.all => const {},
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminDashboardTitle)),
      body: AsyncView<(AdminOverview, List<RequestSummary>)>(
        key: ValueKey(_filter),
        load: () async => (
          await scope.admin.overview(),
          await scope.admin.requests(_statuses),
        ),
        refreshOn: scope.changes,
        builder: (context, data, reload) {
          final (overview, requests) = data;
          final labels = {
            _Filter.attention: l10n.adminFilterAttention,
            _Filter.active: l10n.adminFilterActive,
            _Filter.done: l10n.adminFilterDone,
            _Filter.all: l10n.adminFilterAll,
          };
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm + 4,
                  crossAxisSpacing: AppSpacing.sm + 4,
                  childAspectRatio: 1.55,
                  children: [
                    _Kpi(
                      icon: Icons.support_agent_rounded,
                      tone: AppColors.warning,
                      value: formatCount(overview.count(_attention), lang),
                      label: l10n.kpiNeedsAttention,
                    ),
                    _Kpi(
                      icon: Icons.handyman_rounded,
                      tone: AppColors.progress,
                      value: formatCount(overview.count(_active), lang),
                      label: l10n.kpiInProgress,
                    ),
                    _Kpi(
                      icon: Icons.task_alt_rounded,
                      tone: AppColors.success,
                      value: formatCount(
                        overview.count({RequestStatus.completed}),
                        lang,
                      ),
                      label: l10n.kpiCompleted,
                    ),
                    _Kpi(
                      icon: Icons.account_balance_wallet_outlined,
                      tone: AppColors.info,
                      value: formatEgp(overview.commissionMinor, lang),
                      label: l10n.kpiCommission,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                Card(
                  child: ListTile(
                    leading: const IconBadge(
                      icon: Icons.verified_user_outlined,
                      size: 40,
                    ),
                    title: Text(
                      l10n.kpiPendingApplications(overview.pendingApplications),
                    ),
                    subtitle: Text(
                      l10n.kpiApprovedTechnicians(overview.approvedTechnicians),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.adminRequestsTitle,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _Filter.values) ...[
                        ChoiceChip(
                          label: Text(labels[f]!),
                          selected: f == _filter,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.lg),
                    child: EmptyView(
                      message: l10n.adminRequestsEmpty,
                      icon: Icons.inbox_outlined,
                    ),
                  )
                else
                  for (final r in requests) ...[
                    RequestCard(request: r),
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

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.tone,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final (Color, Color) tone;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconBadge(icon: icon, tone: tone, size: 34),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
