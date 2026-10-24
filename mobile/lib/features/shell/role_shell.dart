import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../admin/presentation/admin_applications_screen.dart';
import '../admin/presentation/admin_dashboard_screen.dart';
import '../auth/domain/auth_models.dart';
import '../auth/presentation/onboarding_screen.dart';
import '../auth/presentation/profile_screen.dart';
import '../auth/presentation/sign_in_screen.dart';
import '../catalog/presentation/home_screen.dart';
import '../jobs/presentation/my_jobs_screen.dart';
import '../jobs/presentation/offers_screen.dart';
import '../notifications/presentation/notifications_screen.dart';
import '../requests/presentation/my_requests_screen.dart';
import '../technician/presentation/technician_application_screen.dart';

/// First launch shows the welcome pages, then sign-in. Each signed-in role gets its own
/// bottom navigation; a technician sees only their application until it is approved.
class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AppScope.of(context).auth;
    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final user = auth.user;
        if (user == null || user.role == UserRole.unknown) {
          return auth.onboardingSeen
              ? const SignInScreen()
              : const OnboardingScreen();
        }
        // Keyed so tabs reset when another account signs in or a technician is approved.
        return RoleShell(
          key: ValueKey('${user.id}:${user.canWork}'),
          role: user.role,
          canWork: user.canWork,
        );
      },
    );
  }
}

class _Tab {
  const _Tab(this.icon, this.selectedIcon, this.label, this.screen);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget screen;
}

class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role, this.canWork = false});

  final UserRole role;

  /// Technicians only: approved to take jobs.
  final bool canWork;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  int _index = 0;

  List<_Tab> _tabs(AppLocalizations l10n) {
    final notifications = _Tab(
      Icons.notifications_none_rounded,
      Icons.notifications_rounded,
      l10n.tabNotifications,
      const NotificationsScreen(),
    );
    final account = _Tab(
      Icons.person_outline_rounded,
      Icons.person_rounded,
      l10n.tabAccount,
      const ProfileScreen(),
    );
    return switch (widget.role) {
      UserRole.technician when !widget.canWork => [
        _Tab(
          Icons.badge_outlined,
          Icons.badge_rounded,
          l10n.tabApplication,
          const TechnicianApplicationScreen(),
        ),
        notifications,
        account,
      ],
      UserRole.technician => [
        _Tab(
          Icons.local_offer_outlined,
          Icons.local_offer_rounded,
          l10n.tabOffers,
          const OffersScreen(),
        ),
        _Tab(
          Icons.work_outline_rounded,
          Icons.work_rounded,
          l10n.tabJobs,
          const MyJobsScreen(),
        ),
        notifications,
        account,
      ],
      UserRole.admin => [
        _Tab(
          Icons.space_dashboard_outlined,
          Icons.space_dashboard_rounded,
          l10n.tabDashboard,
          const AdminDashboardScreen(),
        ),
        _Tab(
          Icons.verified_user_outlined,
          Icons.verified_user_rounded,
          l10n.tabTechnicians,
          const AdminApplicationsScreen(),
        ),
        notifications,
        account,
      ],
      _ => [
        _Tab(
          Icons.home_outlined,
          Icons.home_rounded,
          l10n.tabHome,
          const HomeScreen(),
        ),
        _Tab(
          Icons.assignment_outlined,
          Icons.assignment_rounded,
          l10n.tabRequests,
          const MyRequestsScreen(),
        ),
        notifications,
        account,
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final tabs = _tabs(l10n);
    final notificationsIndex = tabs.length - 2;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (final t in tabs) t.screen],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: ListenableBuilder(
          listenable: scope.changes,
          builder: (context, _) {
            final unread = scope.notifications.unreadCount();
            return NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) {
                // Leaving the notifications tab marks what was seen as read.
                if (_index == notificationsIndex &&
                    i != notificationsIndex &&
                    unread > 0) {
                  scope.notifications.markAllRead().catchError((_) {});
                }
                setState(() => _index = i);
              },
              destinations: [
                for (final (i, t) in tabs.indexed)
                  NavigationDestination(
                    icon: i == notificationsIndex && unread > 0
                        ? Badge.count(count: unread, child: Icon(t.icon))
                        : Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: t.label,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
