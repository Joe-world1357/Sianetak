import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name
  ///
  /// In ar, this message translates to:
  /// **'صيانتك'**
  String get appTitle;

  /// No description provided for @homeHeadline.
  ///
  /// In ar, this message translates to:
  /// **'ما الخدمة التي تحتاجها؟'**
  String get homeHeadline;

  /// No description provided for @homeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الخدمة واطّلع على التفاصيل قبل الطلب.'**
  String get homeSubtitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get categoriesTitle;

  /// Label of the button that switches to the other language
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get switchLanguage;

  /// No description provided for @switchLanguageTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اللغة إلى الإنجليزية'**
  String get switchLanguageTooltip;

  /// No description provided for @accountTooltip.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get accountTooltip;

  /// No description provided for @signInTooltip.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInTooltip;

  /// No description provided for @servicesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد خدمات} =1{خدمة واحدة} =2{خدمتان} few{{count} خدمات} many{{count} خدمة} other{{count} خدمة}}'**
  String servicesCount(int count);

  /// No description provided for @sampleDataBadge.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تجريبية'**
  String get sampleDataBadge;

  /// No description provided for @sampleDataNotice.
  ///
  /// In ar, this message translates to:
  /// **'هذه بيانات تجريبية للعرض فقط ولم تُعتمد بعد.'**
  String get sampleDataNotice;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل…'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'حاول مرة أخرى'**
  String get retry;

  /// No description provided for @emptyCategories.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خدمات متاحة حاليًا. حاول لاحقًا.'**
  String get emptyCategories;

  /// No description provided for @emptyServices.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد خدمات متاحة في هذا القسم حاليًا.'**
  String get emptyServices;

  /// No description provided for @errorLoadTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل البيانات'**
  String get errorLoadTitle;

  /// No description provided for @errorNotFound.
  ///
  /// In ar, this message translates to:
  /// **'العنصر المطلوب غير موجود أو لم يعد متاحًا.'**
  String get errorNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر الاتصال. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get errorGeneric;

  /// No description provided for @priceInspectionRequired.
  ///
  /// In ar, this message translates to:
  /// **'السعر يُحدَّد بعد المعاينة'**
  String get priceInspectionRequired;

  /// No description provided for @priceInspectionExplanation.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سعر تقديري موثوق لهذه الخدمة. سيعاين الفني المشكلة ويرسل لك عرض سعر مفصّل توافق عليه قبل بدء العمل.'**
  String get priceInspectionExplanation;

  /// No description provided for @priceIndicativeRange.
  ///
  /// In ar, this message translates to:
  /// **'سعر تقديري: {min} – {max}'**
  String priceIndicativeRange(String min, String max);

  /// No description provided for @priceIndicativeExplanation.
  ///
  /// In ar, this message translates to:
  /// **'السعر النهائي يُحدَّد بعد المعاينة ويحتاج موافقتك قبل بدء العمل.'**
  String get priceIndicativeExplanation;

  /// No description provided for @pricingTitle.
  ///
  /// In ar, this message translates to:
  /// **'التسعير'**
  String get pricingTitle;

  /// No description provided for @aboutServiceTitle.
  ///
  /// In ar, this message translates to:
  /// **'عن الخدمة'**
  String get aboutServiceTitle;

  /// No description provided for @requestServiceButton.
  ///
  /// In ar, this message translates to:
  /// **'اطلب الخدمة'**
  String get requestServiceButton;

  /// No description provided for @requestComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'تقديم طلبات الخدمة سيتاح قريبًا.'**
  String get requestComingSoon;

  /// No description provided for @signInToRequest.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول لطلب الخدمة'**
  String get signInToRequest;

  /// No description provided for @signInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم الموبايل وسنرسل إليك رمز تحقق في رسالة نصية.'**
  String get signInSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'01XXXXXXXXX'**
  String get phoneHint;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم موبايل مصري صحيح (مثال: 01012345678).'**
  String get phoneInvalid;

  /// No description provided for @sendCodeButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCodeButton;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزًا من {length} أرقام إلى {phone}.'**
  String otpSubtitle(int length, String phone);

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get otpLabel;

  /// No description provided for @otpInvalidFormat.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز كاملًا ({length} أرقام).'**
  String otpInvalidFormat(int length);

  /// No description provided for @verifyButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verifyButton;

  /// No description provided for @resendIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {seconds} ث'**
  String resendIn(int seconds);

  /// No description provided for @resendButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get resendButton;

  /// No description provided for @changeNumber.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get changeNumber;

  /// No description provided for @codeResent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رمز جديد.'**
  String get codeResent;

  /// No description provided for @devCodeBanner.
  ///
  /// In ar, this message translates to:
  /// **'وضع التطوير فقط — لم تُرسل رسالة. الرمز: {code}'**
  String devCodeBanner(String code);

  /// No description provided for @errorOtpInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح. {attempts, plural, =0{لا توجد محاولات متبقية.} =1{تبقّت محاولة واحدة.} =2{تبقّت محاولتان.} few{تبقّت {attempts} محاولات.} other{تبقّت {attempts} محاولة.}}'**
  String errorOtpInvalid(int attempts);

  /// No description provided for @errorOtpInvalidNoCount.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح.'**
  String get errorOtpInvalidNoCount;

  /// No description provided for @errorOtpExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.'**
  String get errorOtpExpired;

  /// No description provided for @errorOtpTooManyAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولات خاطئة كثيرة. اطلب رمزًا جديدًا.'**
  String get errorOtpTooManyAttempts;

  /// No description provided for @errorResendTooSoon.
  ///
  /// In ar, this message translates to:
  /// **'انتظر {seconds} ثانية قبل طلب رمز جديد.'**
  String errorResendTooSoon(int seconds);

  /// No description provided for @errorOtpRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبت رموزًا كثيرة لهذا الرقم. حاول مرة أخرى بعد قليل.'**
  String get errorOtpRateLimited;

  /// No description provided for @errorRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.'**
  String get errorRateLimited;

  /// No description provided for @errorOtpUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول برسائل SMS غير متاح حاليًا.'**
  String get errorOtpUnavailable;

  /// No description provided for @errorOtpDeliveryFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر إرسال الرمز. حاول مرة أخرى.'**
  String get errorOtpDeliveryFailed;

  /// No description provided for @errorAccountSuspended.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف هذا الحساب. تواصل مع الدعم.'**
  String get errorAccountSuspended;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلستك. سجّل الدخول مرة أخرى.'**
  String get errorSessionExpired;

  /// No description provided for @signedInWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا بك! تم تسجيل الدخول.'**
  String get signedInWelcome;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get profileNameLabel;

  /// No description provided for @profileNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك'**
  String get profileNameHint;

  /// No description provided for @profileNameInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمًا من حرفين على الأقل.'**
  String get profileNameInvalid;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get profilePhoneLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get profileRoleLabel;

  /// No description provided for @roleCustomer.
  ///
  /// In ar, this message translates to:
  /// **'عميل'**
  String get roleCustomer;

  /// No description provided for @roleTechnician.
  ///
  /// In ar, this message translates to:
  /// **'فني'**
  String get roleTechnician;

  /// No description provided for @roleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'إدارة'**
  String get roleAdmin;

  /// No description provided for @saveButton.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveButton;

  /// No description provided for @profileSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ البيانات.'**
  String get profileSaved;

  /// No description provided for @signOutButton.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOutButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
