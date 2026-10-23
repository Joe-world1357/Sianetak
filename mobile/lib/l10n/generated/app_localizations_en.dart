// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sianetak';

  @override
  String get homeHeadline => 'What needs fixing?';

  @override
  String get homeSubtitle =>
      'Pick a service type and see the details before you request.';

  @override
  String get categoriesTitle => 'Services';

  @override
  String get switchLanguage => 'العربية';

  @override
  String get switchLanguageTooltip => 'Switch language to Arabic';

  @override
  String get accountTooltip => 'My account';

  @override
  String get signInTooltip => 'Sign in';

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services',
      one: '1 service',
      zero: 'No services',
    );
    return '$_temp0';
  }

  @override
  String get sampleDataBadge => 'Sample data';

  @override
  String get sampleDataNotice =>
      'This is sample data for demonstration only and has not been approved.';

  @override
  String get loading => 'Loading…';

  @override
  String get retry => 'Try again';

  @override
  String get emptyCategories =>
      'No services are available right now. Please check back later.';

  @override
  String get emptyServices =>
      'No services are available in this category right now.';

  @override
  String get errorLoadTitle => 'Couldn\'t load data';

  @override
  String get errorNotFound =>
      'This item doesn\'t exist or is no longer available.';

  @override
  String get errorNetwork =>
      'Couldn\'t connect. Check your internet connection and try again.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get priceInspectionRequired => 'Price set after inspection';

  @override
  String get priceInspectionExplanation =>
      'There\'s no reliable estimate for this service. The technician will inspect the problem and send you an itemized quote to approve before any work starts.';

  @override
  String priceIndicativeRange(String min, String max) {
    return 'Estimated price: $min – $max';
  }

  @override
  String get priceIndicativeExplanation =>
      'The final price is set after inspection and needs your approval before work starts.';

  @override
  String get pricingTitle => 'Pricing';

  @override
  String get aboutServiceTitle => 'About this service';

  @override
  String get requestServiceButton => 'Request this service';

  @override
  String get requestComingSoon => 'Service requests will be available soon.';

  @override
  String get signInToRequest => 'Sign in to request this service';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle =>
      'Enter your mobile number and we\'ll text you a verification code.';

  @override
  String get phoneLabel => 'Mobile number';

  @override
  String get phoneHint => '01XXXXXXXXX';

  @override
  String get phoneInvalid =>
      'Enter a valid Egyptian mobile number (e.g. 01012345678).';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get otpTitle => 'Enter verification code';

  @override
  String otpSubtitle(int length, String phone) {
    return 'We sent a $length-digit code to $phone.';
  }

  @override
  String get otpLabel => 'Verification code';

  @override
  String otpInvalidFormat(int length) {
    return 'Enter the full $length-digit code.';
  }

  @override
  String get verifyButton => 'Verify';

  @override
  String resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get resendButton => 'Resend code';

  @override
  String get changeNumber => 'Change number';

  @override
  String get codeResent => 'A new code has been sent.';

  @override
  String devCodeBanner(String code) {
    return 'Development only — no SMS was sent. Code: $code';
  }

  @override
  String errorOtpInvalid(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '$attempts attempts left.',
      one: '1 attempt left.',
      zero: 'No attempts left.',
    );
    return 'Incorrect code. $_temp0';
  }

  @override
  String get errorOtpInvalidNoCount => 'Incorrect code.';

  @override
  String get errorOtpExpired => 'This code has expired. Request a new one.';

  @override
  String get errorOtpTooManyAttempts =>
      'Too many incorrect attempts. Request a new code.';

  @override
  String errorResendTooSoon(int seconds) {
    return 'Wait $seconds seconds before requesting a new code.';
  }

  @override
  String get errorOtpRateLimited =>
      'Too many codes were requested for this number. Try again later.';

  @override
  String get errorRateLimited =>
      'Too many requests. Wait a moment and try again.';

  @override
  String get errorOtpUnavailable => 'SMS sign-in isn\'t available right now.';

  @override
  String get errorOtpDeliveryFailed =>
      'Couldn\'t send the code. Please try again.';

  @override
  String get errorAccountSuspended =>
      'This account has been suspended. Please contact support.';

  @override
  String get errorSessionExpired =>
      'Your session has ended. Please sign in again.';

  @override
  String get signedInWelcome => 'Welcome! You\'re signed in.';

  @override
  String get profileTitle => 'My account';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileNameHint => 'Enter your name';

  @override
  String get profileNameInvalid => 'Enter a name with at least 2 letters.';

  @override
  String get profilePhoneLabel => 'Mobile number';

  @override
  String get profileRoleLabel => 'Account type';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleTechnician => 'Technician';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get saveButton => 'Save';

  @override
  String get profileSaved => 'Saved.';

  @override
  String get signOutButton => 'Sign out';
}
