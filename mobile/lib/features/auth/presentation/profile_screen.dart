import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../admin/presentation/admin_applications_screen.dart';
import '../../requests/presentation/my_requests_screen.dart';
import '../../technician/presentation/technician_application_screen.dart';
import '../domain/auth_models.dart';
import '../domain/egypt_phone.dart';
import 'auth_error_text.dart';

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
      if (role == UserRole.customer)
        entry(
          Icons.assignment_outlined,
          l10n.myRequestsEntry,
          () => const MyRequestsScreen(),
        ),
      if (role == UserRole.customer || role == UserRole.technician) ...[
        const SizedBox(height: AppSpacing.sm),
        entry(
          Icons.handyman_outlined,
          role == UserRole.technician
              ? l10n.technicianEntryStatus
              : l10n.technicianEntryApply,
          () => const TechnicianApplicationScreen(),
        ),
      ],
      if (role == UserRole.admin)
        entry(
          Icons.verified_user_outlined,
          l10n.adminReviewEntry,
          () => const AdminApplicationsScreen(),
        ),
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

  Future<void> _signOut() async {
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);
    await auth.signOut();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: user == null
          ? EmptyView(
              message: l10n.errorSessionExpired,
              icon: Icons.lock_outline,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_iphone),
                  title: Text(l10n.profilePhoneLabel),
                  // Isolate the number so it reads left-to-right inside Arabic text.
                  subtitle: Text(isolateLtr(displayLocalPhone(user.phone))),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(l10n.profileRoleLabel),
                  subtitle: Text(_roleLabel(l10n, user.role)),
                ),
                const SizedBox(height: AppSpacing.md),
                Form(
                  key: _formKey,
                  child: TextFormField(
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
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AuthErrorText(_error!),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(l10n.saveButton),
                ),
                const SizedBox(height: AppSpacing.lg),
                ..._roleEntries(context, l10n, user.role),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.signOutButton),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
    );
  }
}
