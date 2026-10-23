import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../network/api_exception.dart';
import '../theme/app_theme.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Semantics(
        label: l10n.loading,
        liveRegion: true,
        child: const CircularProgressIndicator(),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessage(icon: icon, title: message);
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isNotFound =
        error is ApiException && (error as ApiException).isNotFound;
    return _CenteredMessage(
      icon: isNotFound ? Icons.search_off : Icons.wifi_off_rounded,
      title: isNotFound ? l10n.errorNotFound : l10n.errorLoadTitle,
      body: isNotFound ? null : messageForError(l10n, error),
      action: isNotFound
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 56, color: theme.colorScheme.outline),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                body!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Maps API error codes to localized, user-facing copy.
String messageForError(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return l10n.errorGeneric;
  switch (error.code) {
    case ApiException.network:
      return l10n.errorNetwork;
    case 'INVALID_PHONE':
      return l10n.phoneInvalid;
    case 'OTP_INVALID':
      final attempts = error.intDetail('attemptsRemaining');
      return attempts == null
          ? l10n.errorOtpInvalidNoCount
          : l10n.errorOtpInvalid(attempts);
    case 'OTP_EXPIRED':
      return l10n.errorOtpExpired;
    case 'OTP_TOO_MANY_ATTEMPTS':
      return l10n.errorOtpTooManyAttempts;
    case 'OTP_RESEND_TOO_SOON':
      return l10n.errorResendTooSoon(
        error.intDetail('retryAfterSeconds') ?? 60,
      );
    case 'OTP_RATE_LIMITED':
      return l10n.errorOtpRateLimited;
    case 'RATE_LIMITED':
      return l10n.errorRateLimited;
    case 'OTP_DELIVERY_UNAVAILABLE':
      return l10n.errorOtpUnavailable;
    case 'OTP_DELIVERY_FAILED':
      return l10n.errorOtpDeliveryFailed;
    case 'ACCOUNT_SUSPENDED':
      return l10n.errorAccountSuspended;
    case 'UNAUTHENTICATED':
    case 'REFRESH_TOKEN_INVALID':
      return l10n.errorSessionExpired;
    case 'CATEGORY_NOT_FOUND':
    case 'SERVICE_NOT_FOUND':
    case 'NOT_FOUND':
    case 'REQUEST_NOT_FOUND':
    case 'MEDIA_NOT_FOUND':
    case 'APPLICATION_NOT_FOUND':
      return l10n.errorNotFound;
    case 'VALIDATION_FAILED':
      return l10n.errorValidation;
    case 'FORBIDDEN':
    case 'APPLICATION_NOT_ALLOWED':
    case 'TECHNICIAN_NOT_ELIGIBLE':
      return l10n.errorForbidden;
    case 'SERVICE_NOT_AVAILABLE':
      return l10n.errorServiceNotAvailable;
    case 'AREA_NOT_AVAILABLE':
      return l10n.errorAreaNotAvailable;
    case 'LOCATION_OUT_OF_AREA':
      return l10n.errorLocationOutOfArea;
    case 'LOCATION_REQUIRED':
      return l10n.addressMissing;
    case 'INVALID_SCHEDULE':
      return l10n.errorInvalidSchedule;
    case 'TOO_MANY_OPEN_REQUESTS':
      return l10n.errorTooManyOpenRequests;
    case 'MEDIA_INVALID':
    case 'MEDIA_TOO_MANY':
      return l10n.errorMediaInvalid;
    case 'FILE_TOO_LARGE':
      return l10n.errorFileTooLarge;
    case 'UNSUPPORTED_FILE_TYPE':
      return l10n.errorUnsupportedFile;
    case 'MEDIA_STORAGE_UNAVAILABLE':
      return l10n.errorMediaUnavailable;
    case 'MEDIA_PENDING_LIMIT':
      return l10n.errorMediaPendingLimit;
    case 'ADDRESS_NOT_FOUND':
      return l10n.errorAddressNotFound;
    case 'ADDRESS_LIMIT_REACHED':
      return l10n.errorAddressLimit;
    case 'APPLICATION_ALREADY_SUBMITTED':
      return l10n.errorApplicationAlreadySubmitted;
    case 'APPLICATION_STATE_CONFLICT':
      return l10n.errorApplicationStateConflict;
    case 'CATEGORY_NOT_AVAILABLE':
      return l10n.errorCategoryNotAvailable;
    case 'DOCUMENTS_REQUIRED':
      return l10n.errorDocumentsRequired(error.intDetail('min') ?? 1);
    case 'CANNOT_REVIEW_OWN_APPLICATION':
      return l10n.errorCannotReviewOwn;
    default:
      return l10n.errorGeneric;
  }
}
