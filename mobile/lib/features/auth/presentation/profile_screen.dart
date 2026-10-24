import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../technician/presentation/technician_application_screen.dart';
import '../domain/auth_models.dart';
import '../domain/egypt_phone.dart';
import 'auth_error_text.dart';
import 'sign_in_screen.dart';

/// Signed-in user's profile foundation: name, phone, role and sign-out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.getInheritedWidgetOfExactType<AppScope>()!.auth;
    _name = TextEditingController(text: auth.user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String _roleLabel(AppLocalizations l10n, UserRole role) => switch (role) {
    UserRole.customer => l10n.roleCustomer,
    UserRole.technician => l10n.roleTechnician,
    UserRole.admin => l10n.roleAdmin,
    UserRole.unknown => '—',
  };

  /// Role-specific destinations. The server enforces each role; this only hides dead ends.
  List<Widget> _roleEntries(
    BuildContext context,
    AppLocalizations l10n,
    UserRole role,
  ) {
    Widget entry(IconData icon, String title, Widget Function() screen) => Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => screen())),
      ),
    );
    return [
      if (role == UserRole.customer || role == UserRole.technician) ...[
        entry(
          Icons.handyman_outlined,
          role == UserRole.technician
              ? l10n.technicianEntryStatus
              : l10n.technicianEntryApply,
          () => const TechnicianApplicationScreen(),
        ),
      ],
    ];
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.updateName(_name.text.trim());
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
    } catch (e) {
      if (mounted) setState(() => _error = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() => AppScope.of(context).auth.signOut();

  Future<void> _switchAccount() async {
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);
    await auth.signOut();
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  Future<void> _resetDemo() async {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetDemoTitle),
        content: Text(l10n.resetDemoBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resetDemoButton),
          ),
        ],
      ),
    );
    if (ok != true || scope.resetDemo == null) return;
    await scope.resetDemo!();
    await scope.auth.restore();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final user = scope.auth.user;
    final theme = Theme.of(context);

    Widget setting(
      IconData icon,
      String title,
      VoidCallback onTap, {
      String? trailing,
      Color? color,
    }) => ListTile(
      leading: Icon(icon, color: color ?? AppColors.muted),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing == null
          ? const Icon(Icons.chevron_right, color: AppColors.muted)
          : Text(
              trailing,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: user == null
          ? EmptyView(
              message: l10n.errorSessionExpired,
              icon: Icons.lock_outline,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            (user.name ?? '').trim().isEmpty
                                ? '؟'
                                : user.name!.trim().characters.first,
                            style: theme.textTheme.headlineSmall?.copyWith(
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
                                user.name ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              // Isolate the number so it reads left-to-right in Arabic.
                              Text(
                                isolateLtr(displayLocalPhone(user.phone)),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              TonePill(
                                label: _roleLabel(l10n, user.role),
                                tone: AppColors.info,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            maxLength: 80,
                            decoration: InputDecoration(
                              labelText: l10n.profileNameLabel,
                              hintText: l10n.profileNameHint,
                            ),
                            validator: (v) => (v?.trim().length ?? 0) < 2
                                ? l10n.profileNameInvalid
                                : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AuthErrorText(_error!),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(l10n.saveButton),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ..._roleEntries(context, l10n, user.role),
                const SizedBox(height: AppSpacing.md),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      setting(
                        Icons.translate_rounded,
                        l10n.languageSetting,
                        scope.locale.toggle,
                        trailing: l10n.switchLanguage,
                      ),
                      const Divider(indent: 56),
                      setting(
                        Icons.switch_account_rounded,
                        l10n.switchAccountButton,
                        _switchAccount,
                      ),
                      if (scope.resetDemo != null) ...[
                        const Divider(indent: 56),
                        setting(
                          Icons.restart_alt_rounded,
                          l10n.resetDemoButton,
                          _resetDemo,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOutButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }
}
