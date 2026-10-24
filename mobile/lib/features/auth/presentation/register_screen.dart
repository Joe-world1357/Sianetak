import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_models.dart';
import 'auth_error_text.dart';
import 'auth_widgets.dart';

enum RegisterMode {
  /// Self-service sign-up: customer or technician.
  signUp,

  /// One-time creation of this device's first administrator.
  adminSetup,

  /// An administrator adding another administrator.
  addAdmin,
}

/// Account creation. Administrators can never sign up through [RegisterMode.signUp].
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.mode});

  final RegisterMode mode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  AccountType _type = AccountType.customer;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final name = _name.text.trim();
      switch (widget.mode) {
        case RegisterMode.signUp:
          await auth.register(
            name: name,
            phone: _phone.text,
            password: _password.text,
            type: _type,
          );
        case RegisterMode.adminSetup:
          await auth.setupAdmin(
            name: name,
            phone: _phone.text,
            password: _password.text,
          );
        case RegisterMode.addAdmin:
          await auth.createAdmin(
            name: name,
            phone: _phone.text,
            password: _password.text,
          );
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.adminAdded(name))),
          );
      }
      // Signing up switches the root to the new account's home; close this screen.
      if (mounted) navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _error = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (title, subtitle, button) = switch (widget.mode) {
      RegisterMode.signUp => (
        l10n.registerTitle,
        l10n.registerSubtitle,
        l10n.registerButton,
      ),
      RegisterMode.adminSetup => (
        l10n.adminSetupTitle,
        l10n.adminSetupBody,
        l10n.adminSetupButton,
      ),
      RegisterMode.addAdmin => (
        l10n.addAdminTitle,
        l10n.addAdminBody,
        l10n.addAdminButton,
      ),
    };
    return AuthLayout(
      appBar: AppBar(),
      children: [
        AuthHeader(title: title, subtitle: subtitle),
        const SizedBox(height: AppSpacing.lg),
        if (widget.mode == RegisterMode.signUp) ...[
          Text(
            l10n.accountTypeLabel,
            style: theme.textTheme.labelLarge?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AccountTypeOption(
            selected: _type == AccountType.customer,
            icon: Icons.home_outlined,
            title: l10n.roleCustomer,
            body: l10n.accountTypeCustomerBlurb,
            onTap: () => setState(() => _type = AccountType.customer),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AccountTypeOption(
            selected: _type == AccountType.technician,
            icon: Icons.engineering_outlined,
            title: l10n.roleTechnician,
            body: l10n.accountTypeTechnicianBlurb,
            onTap: () => setState(() => _type = AccountType.technician),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: l10n.profileNameLabel,
                    hintText: l10n.profileNameHint,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    counterText: '',
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? l10n.profileNameInvalid
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                PhoneField(controller: _phone),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
                  helper: l10n.passwordRules,
                  strict: true,
                  newPassword: true,
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _confirm,
                  label: l10n.passwordConfirmLabel,
                  matches: _password,
                  newPassword: true,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthErrorText(_error!),
        ],
        const SizedBox(height: AppSpacing.lg),
        BusyButton(label: button, busy: _busy, onPressed: _submit),
        if (widget.mode == RegisterMode.signUp) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.haveAccountPrompt, style: theme.textTheme.bodyMedium),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.signInLink),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const LocalDataNote(),
        ],
      ],
    );
  }
}

/// One selectable account type: outlined, highlighted in the brand colour when chosen.
class _AccountTypeOption extends StatelessWidget {
  const _AccountTypeOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.primary : AppColors.line;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? AppColors.info.$2 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(color: color, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
