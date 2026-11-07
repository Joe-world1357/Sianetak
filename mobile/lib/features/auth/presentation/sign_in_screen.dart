import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_error_text.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

/// Phone + password sign-in: the entry point for signed-out users. Links to sign-up and,
/// only while this device has no administrator yet, to the one-time administrator setup.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool? _hasAdmin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAdmin == null) _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final hasAdmin = await AppScope.of(context).auth.hasAdmin();
    if (mounted) setState(() => _hasAdmin = hasAdmin);
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.signIn(phone: _phone.text, password: _password.text);
    } catch (e) {
      if (mounted) {
        setState(() => _error = messageForError(l10n, e));
        _password.clear();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(RegisterMode mode) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => RegisterScreen(mode: mode)));
    if (mounted) _checkAdmin();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    final theme = Theme.of(context);
    return AuthLayout(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: scope.locale.toggle,
            child: Semantics(
              label: l10n.switchLanguageTooltip,
              excludeSemantics: true,
              child: Text(l10n.switchLanguage),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      children: [
        AuthHeader(
          title: l10n.signInTitle,
          subtitle: l10n.signInSubtitle,
          showMark: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhoneField(controller: _phone),
                const SizedBox(height: AppSpacing.md),
                PasswordField(
                  controller: _password,
                  label: l10n.passwordLabel,
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
        BusyButton(label: l10n.signInButton, busy: _busy, onPressed: _submit),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.noAccountPrompt, style: theme.textTheme.bodyMedium),
            TextButton(
              onPressed: () => _open(RegisterMode.signUp),
              child: Text(l10n.createAccountLink),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const LocalDataNote(),
        if (_hasAdmin == false) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.adminSetupPrompt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              TextButton.icon(
                onPressed: () => _open(RegisterMode.adminSetup),
                icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
                label: Text(l10n.adminSetupLink),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
