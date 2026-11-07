import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'auth_error_text.dart';
import 'auth_widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
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
      await auth.changePassword(current: _current.text, next: _next.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordChanged)));
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _error = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePasswordTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            PasswordField(
              controller: _current,
              label: l10n.currentPasswordLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _next,
              label: l10n.newPasswordLabel,
              helper: l10n.passwordRules,
              strict: true,
              newPassword: true,
            ),
            const SizedBox(height: AppSpacing.md),
            PasswordField(
              controller: _confirm,
              label: l10n.passwordConfirmLabel,
              matches: _next,
              newPassword: true,
              action: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              AuthErrorText(_error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            BusyButton(label: l10n.saveButton, busy: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
