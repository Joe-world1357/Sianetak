import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../admin/presentation/admin_applications_screen.dart';
import '../../auth/domain/auth_models.dart';
import '../../auth/domain/egypt_phone.dart';
import '../../requests/presentation/request_detail_screen.dart';
import '../../technician/presentation/technician_application_screen.dart';
import '../data/notifications_repository.dart';

/// The signed-in user's in-app notices, newest first. Opening the screen marks them read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _markRead() =>
      AppScope.of(context).notifications.markAllRead().catchError((_) {});

  void _open(AppNotification n) {
    final role = AppScope.of(context).auth.user?.role;
    final Widget? screen = n.requestId != null
        ? RequestDetailScreen(requestId: n.requestId!)
        : n.applicationId == null
        ? null
        : role == UserRole.admin
        ? AdminApplicationDetailScreen(applicationId: n.applicationId!)
        : const TechnicianApplicationScreen();
    if (screen == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final unread = scope.notifications.unreadCount();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          if (unread > 0)
            TextButton(onPressed: _markRead, child: Text(l10n.markAllRead)),
        ],
      ),
      body: AsyncView<List<AppNotification>>(
        load: scope.notifications.list,
        refreshOn: scope.changes,
        builder: (context, items, reload) => RefreshIndicator(
          onRefresh: reload,
          child: items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    EmptyView(
                      message: l10n.notificationsEmpty,
                      icon: Icons.notifications_none_rounded,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(indent: 76, endIndent: AppSpacing.md),
                  itemBuilder: (context, i) => _Tile(
                    notification: items[i],
                    onTap: () => _open(items[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

(IconData, (Color, Color)) _visual(String type) => switch (type) {
  'new_offer' ||
  'assigned_by_admin' => (Icons.local_offer_rounded, AppColors.info),
  'assigned' => (Icons.how_to_reg_rounded, AppColors.progress),
  'en_route' => (Icons.directions_car_rounded, AppColors.progress),
  'arrived' => (Icons.location_on_rounded, AppColors.progress),
  'quoted' ||
  'quote_rejected' => (Icons.request_quote_rounded, AppColors.warning),
  'quote_approved' => (Icons.thumb_up_alt_rounded, AppColors.success),
  'completed' ||
  'application_approved' => (Icons.task_alt_rounded, AppColors.success),
  'rated' => (Icons.star_rounded, AppColors.warning),
  'message' => (Icons.chat_bubble_rounded, AppColors.info),
  'request_cancelled' ||
  'application_rejected' ||
  'application_suspended' => (Icons.cancel_rounded, AppColors.danger),
  'request_unmatched' => (Icons.support_agent_rounded, AppColors.warning),
  'application_submitted' => (Icons.badge_rounded, AppColors.info),
  _ => (Icons.notifications_rounded, AppColors.neutral),
};

String notificationText(AppLocalizations l10n, AppNotification n) {
  final ref = isolateLtr(n.reference ?? '');
  return switch (n.type) {
    'new_offer' => l10n.ntfNewOffer(ref),
    'assigned_by_admin' => l10n.ntfAssignedByAdmin(ref),
    'assigned' => l10n.ntfAssigned(ref),
    'en_route' => l10n.ntfEnRoute(ref),
    'arrived' => l10n.ntfArrived(ref),
    'quoted' => l10n.ntfQuoted(ref),
    'quote_approved' => l10n.ntfQuoteApproved(ref),
    'quote_rejected' => l10n.ntfQuoteRejected(ref),
    'completed' => l10n.ntfCompleted(ref),
    'rated' => l10n.ntfRated(ref),
    'message' => l10n.ntfMessage(ref),
    'request_cancelled' => l10n.ntfCancelled(ref),
    'request_unmatched' => l10n.ntfUnmatched(ref),
    'application_submitted' => l10n.ntfApplicationSubmitted,
    'application_approved' => l10n.ntfApplicationApproved,
    'application_rejected' => l10n.ntfApplicationRejected,
    'application_suspended' => l10n.ntfApplicationSuspended,
    _ => n.type,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final (icon, tone) = _visual(notification.type);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: icon, tone: tone),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notificationText(l10n, notification),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: notification.read
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(notification.at, lang),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.read)
              Container(
                margin: const EdgeInsetsDirectional.only(
                  start: AppSpacing.sm,
                  top: 6,
                ),
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
