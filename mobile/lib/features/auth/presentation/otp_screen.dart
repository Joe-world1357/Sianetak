import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_scope.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/auth_models.dart';
import '../domain/egypt_phone.dart';
import 'auth_error_text.dart';

/// Step 2 of phone OTP sign-in. Pops with `true` on success.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.initialChallenge});

  final OtpChallenge initialChallenge;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  late OtpChallenge _challenge = widget.initialChallenge;
  Timer? _timer;
  int _resendIn = 0;
  bool _busy = false;
  String? _error;

  /// After these errors the current code can no longer work; the user must request a new one.
  bool _needsNewCode = false;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(_challenge.resendAfterSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendIn = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      await auth.verifyOtp(_challenge, toAsciiDigits(_code.text.trim()));
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.signedInWelcome)));
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = messageForError(l10n, e);
        _needsNewCode =
            e is ApiException &&
            (e.code == 'OTP_EXPIRED' || e.code == 'OTP_TOO_MANY_ATTEMPTS');
      });
      _code.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_busy || _resendIn > 0) return;
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await auth.requestOtp(_challenge.phone);
      if (!mounted) return;
      setState(() {
        _challenge = next;
        _needsNewCode = false;
      });
      _code.clear();
      _startResendCountdown(next.resendAfterSeconds);
      messenger.showSnackBar(SnackBar(content: Text(l10n.codeResent)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = messageForError(l10n, e));
      if (e is ApiException && e.code == 'OTP_RESEND_TOO_SOON') {
        _startResendCountdown(e.intDetail('retryAfterSeconds') ?? 60);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final length = _challenge.codeLength;
    final devCode = kReleaseMode ? null : _challenge.devCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.otpTitle)),
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
                    Text(
                      // The number is isolated so it reads left-to-right inside Arabic text.
                      l10n.otpSubtitle(
                        length,
                        isolateLtr(displayLocalPhone(_challenge.phone)),
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (devCode != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _DevCodeBanner(text: l10n.devCodeBanner(devCode)),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _code,
                      autofocus: true,
                      enabled: !_needsNewCode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        letterSpacing: 8,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9٠-٩۰-۹]'),
                        ),
                        LengthLimitingTextInputFormatter(length),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.otpLabel,
                        counterText: '',
                      ),
                      validator: (value) =>
                          RegExp('^\\d{$length}\$')
                              .hasMatch(toAsciiDigits(value?.trim() ?? ''))
                          ? null
                          : l10n.otpInvalidFormat(length),
                      onChanged: (value) {
                        if (toAsciiDigits(value).length == length) _verify();
                      },
                      onFieldSubmitted: (_) => _verify(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AuthErrorText(_error!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _busy || _needsNewCode ? null : _verify,
                      child: _busy
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                semanticsLabel: l10n.loading,
                              ),
                            )
                          : Text(l10n.verifyButton),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _busy || _resendIn > 0 ? null : _resend,
                      child: Text(
                        _resendIn > 0
                            ? l10n.resendIn(_resendIn)
                            : l10n.resendButton,
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(l10n.changeNumber),
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

class _DevCodeBanner extends StatelessWidget {
  const _DevCodeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.sampleBadgeBackground,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.sampleBadge),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.sampleBadge,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
