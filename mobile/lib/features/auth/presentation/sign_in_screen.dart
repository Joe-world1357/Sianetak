import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_models.dart';
import 'auth_error_text.dart';

/// Demo sign-in: choose the customer, technician or admin account. Pops with `true` once
/// signed in. (The phone OTP sign-in needs an SMS provider and is not part of the demo.)
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late final Future<List<AppUser>> _accounts = AppScope.of(context).auth
      .demoAccounts();
  String? _busyId;
  String? _error;

  Future<void> _choose(AppUser account) async {
    if (_busyId != null) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);
    setState(() {
      _busyId = account.id;
      _error = null;
    });
    try {
      await auth.signInAs(account.id);
      if (mounted && navigator.canPop()) navigator.pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppMark(size: 72)),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.signInTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FutureBuilder<List<AppUser>>(
                    future: _accounts,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return AuthErrorText(
                          messageForError(l10n, snapshot.error!),
                        );
                      }
                      final accounts = snapshot.data;
                      if (accounts == null) return const LoadingView();
                      return Column(
                        children: [
                          for (final a in accounts) ...[
                            _RoleCard(
                              account: a,
                              busy: _busyId == a.id,
                              onTap: () => _choose(a),
                            ),
                            const SizedBox(height: AppSpacing.sm + 4),
                          ],
                        ],
                      );
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AuthErrorText(_error!),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.phone_android_rounded,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.demoOfflineNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.account,
    required this.busy,
    required this.onTap,
  });

  final AppUser account;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (icon, tone, role, blurb) = switch (account.role) {
      UserRole.technician => (
        Icons.engineering_rounded,
        AppColors.progress,
        l10n.roleTechnician,
        l10n.demoTechnicianBlurb,
      ),
      UserRole.admin => (
        Icons.admin_panel_settings_rounded,
        AppColors.warning,
        l10n.roleAdmin,
        l10n.demoAdminBlurb,
      ),
      _ => (
        Icons.home_rounded,
        AppColors.info,
        l10n.roleCustomer,
        l10n.demoCustomerBlurb,
      ),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconBadge(icon: icon, tone: tone, size: 52),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      account.name ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tone.$1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blurb,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
