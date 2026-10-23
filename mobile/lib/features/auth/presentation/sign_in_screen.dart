import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/egypt_phone.dart';
import 'auth_error_text.dart';
import 'otp_screen.dart';

/// Step 1 of phone OTP sign-in. Pops with `true` once the user has signed in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final phone = normalizeEgyptMobile(_phone.text)!;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);
    try {
      final challenge = await auth.requestOtp(phone);
      if (!mounted) return;
      final signedIn = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => OtpScreen(initialChallenge: challenge),
        ),
      );
      if (signedIn == true && mounted) navigator.pop(true);
    } catch (e) {
      if (mounted) setState(() => _serverError = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signInTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l10n.signInSubtitle, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _phone,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      // Phone numbers read left-to-right even in Arabic.
                      textDirection: TextDirection.ltr,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9٠-٩۰-۹+\s-]'),
                        ),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.phoneLabel,
                        hintText: l10n.phoneHint,
                        hintTextDirection: TextDirection.ltr,
                        prefixIcon: const Icon(Icons.phone_iphone),
                      ),
                      validator: (value) =>
                          normalizeEgyptMobile(value ?? '') == null
                          ? l10n.phoneInvalid
                          : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_serverError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AuthErrorText(_serverError!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                semanticsLabel: l10n.loading,
                              ),
                            )
                          : Text(l10n.sendCodeButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
