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

  /// No description provided for @nextButton.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get nextButton;

  /// No description provided for @backButton.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get backButton;

  /// No description provided for @cancelButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancelButton;

  /// No description provided for @confirmButton.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirmButton;

  /// No description provided for @editButton.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get editButton;

  /// No description provided for @stepOf.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة {current} من {total}'**
  String stepOf(int current, int total);

  /// No description provided for @requestFlowTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب خدمة'**
  String get requestFlowTitle;

  /// No description provided for @stepDescribeTitle.
  ///
  /// In ar, this message translates to:
  /// **'صف المشكلة'**
  String get stepDescribeTitle;

  /// No description provided for @stepLocationTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الخدمة'**
  String get stepLocationTitle;

  /// No description provided for @stepScheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموعد'**
  String get stepScheduleTitle;

  /// No description provided for @stepReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الطلب'**
  String get stepReviewTitle;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'وصف المشكلة'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تسريب مياه تحت حوض المطبخ منذ يومين'**
  String get descriptionHint;

  /// No description provided for @descriptionTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب وصفًا من {min} أحرف على الأقل.'**
  String descriptionTooShort(int min);

  /// No description provided for @descriptionTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الوصف أطول من {max} حرف.'**
  String descriptionTooLong(int max);

  /// No description provided for @photosTitle.
  ///
  /// In ar, this message translates to:
  /// **'صور (اختياري)'**
  String get photosTitle;

  /// No description provided for @photosHelp.
  ///
  /// In ar, this message translates to:
  /// **'{max, plural, =1{أضف صورة واحدة توضح المشكلة.} =2{أضف حتى صورتين توضحان المشكلة.} few{أضف حتى {max} صور توضح المشكلة.} other{أضف حتى {max} صورة توضح المشكلة.}} تُحذف بيانات الموقع من الصور تلقائيًا.'**
  String photosHelp(int max);

  /// No description provided for @addPhotoCamera.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get addPhotoCamera;

  /// No description provided for @addPhotoGallery.
  ///
  /// In ar, this message translates to:
  /// **'من المعرض'**
  String get addPhotoGallery;

  /// No description provided for @photoUploading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع الصورة'**
  String get photoUploading;

  /// No description provided for @photoFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر رفع الصورة'**
  String get photoFailed;

  /// No description provided for @photoRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة رفع الصورة'**
  String get photoRetry;

  /// No description provided for @photoRemove.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصورة'**
  String get photoRemove;

  /// No description provided for @photoNumber.
  ///
  /// In ar, this message translates to:
  /// **'صورة {number}'**
  String photoNumber(int number);

  /// No description provided for @photosUploadingWait.
  ///
  /// In ar, this message translates to:
  /// **'انتظر حتى يكتمل رفع الصور.'**
  String get photosUploadingWait;

  /// No description provided for @photosFailedFix.
  ///
  /// In ar, this message translates to:
  /// **'أعد رفع الصور التي فشلت أو احذفها.'**
  String get photosFailedFix;

  /// No description provided for @photoLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'{max, plural, =1{يمكنك إضافة صورة واحدة فقط.} =2{يمكنك إضافة صورتين كحد أقصى.} few{يمكنك إضافة {max} صور كحد أقصى.} other{يمكنك إضافة {max} صورة كحد أقصى.}}'**
  String photoLimitReached(int max);

  /// No description provided for @photoTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الصورة كبيرة جدًا. اختر صورة أصغر.'**
  String get photoTooLarge;

  /// No description provided for @photoUploadsUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'رفع الصور غير متاح حاليًا. يمكنك إرسال الطلب بدون صور.'**
  String get photoUploadsUnavailable;

  /// No description provided for @photoPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول إلى الكاميرا أو الصور. يمكنك السماح بذلك من إعدادات الجهاز، أو المتابعة بدون صور.'**
  String get photoPermissionDenied;

  /// No description provided for @photoPickFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر فتح الصورة. حاول مرة أخرى.'**
  String get photoPickFailed;

  /// No description provided for @savedAddressesTitle.
  ///
  /// In ar, this message translates to:
  /// **'عناويني المحفوظة'**
  String get savedAddressesTitle;

  /// No description provided for @newAddressOption.
  ///
  /// In ar, this message translates to:
  /// **'عنوان جديد'**
  String get newAddressOption;

  /// No description provided for @areaLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة'**
  String get areaLabel;

  /// No description provided for @areaRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر المنطقة.'**
  String get areaRequired;

  /// No description provided for @addressDetailsLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان بالتفصيل'**
  String get addressDetailsLabel;

  /// No description provided for @addressDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'الشارع، رقم العمارة، الدور، الشقة'**
  String get addressDetailsHint;

  /// No description provided for @addressDetailsTooShort.
  ///
  /// In ar, this message translates to:
  /// **'اكتب العنوان بتفصيل أكثر.'**
  String get addressDetailsTooShort;

  /// No description provided for @landmarkLabel.
  ///
  /// In ar, this message translates to:
  /// **'علامة مميزة (اختياري)'**
  String get landmarkLabel;

  /// No description provided for @addressLabelLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العنوان (اختياري)'**
  String get addressLabelLabel;

  /// No description provided for @addressLabelHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: البيت، العمل'**
  String get addressLabelHint;

  /// No description provided for @saveAddressLabel.
  ///
  /// In ar, this message translates to:
  /// **'احفظ هذا العنوان للمرات القادمة'**
  String get saveAddressLabel;

  /// No description provided for @useCurrentLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي الحالي'**
  String get useCurrentLocation;

  /// No description provided for @locating.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك…'**
  String get locating;

  /// No description provided for @locationCaptured.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة موقعك الحالي إلى العنوان.'**
  String get locationCaptured;

  /// No description provided for @locationRemove.
  ///
  /// In ar, this message translates to:
  /// **'إزالة الموقع'**
  String get locationRemove;

  /// No description provided for @locationOptionalNote.
  ///
  /// In ar, this message translates to:
  /// **'الموقع اختياري ويساعد في الوصول إليك. لا يُستخدم إلا لطلباتك.'**
  String get locationOptionalNote;

  /// No description provided for @locationDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يُسمح بالوصول إلى الموقع. اكتب العنوان يدويًا.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'الوصول إلى الموقع مرفوض. يمكنك السماح به من إعدادات الجهاز، أو كتابة العنوان يدويًا.'**
  String get locationDeniedForever;

  /// No description provided for @locationServiceOff.
  ///
  /// In ar, this message translates to:
  /// **'خدمة الموقع مغلقة في جهازك. شغّلها أو اكتب العنوان يدويًا.'**
  String get locationServiceOff;

  /// No description provided for @locationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحديد موقعك. اكتب العنوان يدويًا.'**
  String get locationUnavailable;

  /// No description provided for @addressMissing.
  ///
  /// In ar, this message translates to:
  /// **'اختر عنوانًا.'**
  String get addressMissing;

  /// No description provided for @noAreasConfigured.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مناطق خدمة متاحة حاليًا.'**
  String get noAreasConfigured;

  /// No description provided for @scheduleAsap.
  ///
  /// In ar, this message translates to:
  /// **'في أقرب وقت'**
  String get scheduleAsap;

  /// No description provided for @scheduleAsapHint.
  ///
  /// In ar, this message translates to:
  /// **'بدون موعد محدد.'**
  String get scheduleAsapHint;

  /// No description provided for @scheduleChooseSlot.
  ///
  /// In ar, this message translates to:
  /// **'أو اختر موعدًا'**
  String get scheduleChooseSlot;

  /// No description provided for @scheduleNoSlots.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد متاحة حاليًا.'**
  String get scheduleNoSlots;

  /// No description provided for @scheduleMissing.
  ///
  /// In ar, this message translates to:
  /// **'اختر موعدًا أو «في أقرب وقت».'**
  String get scheduleMissing;

  /// No description provided for @slotRange.
  ///
  /// In ar, this message translates to:
  /// **'{day}، {from} – {to}'**
  String slotRange(String day, String from, String to);

  /// No description provided for @reviewServiceLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة'**
  String get reviewServiceLabel;

  /// No description provided for @reviewDescriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'المشكلة'**
  String get reviewDescriptionLabel;

  /// No description provided for @reviewPhotosLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get reviewPhotosLabel;

  /// No description provided for @reviewNoPhotos.
  ///
  /// In ar, this message translates to:
  /// **'بدون صور'**
  String get reviewNoPhotos;

  /// No description provided for @reviewLocationLabel.
  ///
  /// In ar, this message translates to:
  /// **'العنوان'**
  String get reviewLocationLabel;

  /// No description provided for @reviewScheduleLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموعد'**
  String get reviewScheduleLabel;

  /// No description provided for @reviewPricingLabel.
  ///
  /// In ar, this message translates to:
  /// **'التسعير والرسوم'**
  String get reviewPricingLabel;

  /// No description provided for @feeInspection.
  ///
  /// In ar, this message translates to:
  /// **'رسوم المعاينة: {amount}'**
  String feeInspection(String amount);

  /// No description provided for @feeNoneAtSubmission.
  ///
  /// In ar, this message translates to:
  /// **'لا تُدفع أي رسوم عند إرسال الطلب. أي سعر أو رسوم ستُعرض عليك لتوافق عليها قبل بدء العمل.'**
  String get feeNoneAtSubmission;

  /// No description provided for @reviewNextSteps.
  ///
  /// In ar, this message translates to:
  /// **'بعد الإرسال سنراجع طلبك. لم يُعيَّن فني بعد.'**
  String get reviewNextSteps;

  /// No description provided for @submitRequestButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitRequestButton;

  /// No description provided for @submittingLabel.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الإرسال…'**
  String get submittingLabel;

  /// No description provided for @submitFailedRetry.
  ///
  /// In ar, this message translates to:
  /// **'لم يُرسل الطلب. تحقق من الاتصال واضغط «إرسال الطلب» مرة أخرى، ولن يتكرر طلبك.'**
  String get submitFailedRetry;

  /// No description provided for @requestSubmittedTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك'**
  String get requestSubmittedTitle;

  /// No description provided for @requestReferenceLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطلب'**
  String get requestReferenceLabel;

  /// No description provided for @requestSubmittedBody.
  ///
  /// In ar, this message translates to:
  /// **'حالة الطلب: «تم الاستلام». يمكنك متابعته من «طلباتي».'**
  String get requestSubmittedBody;

  /// No description provided for @viewRequestButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض الطلب'**
  String get viewRequestButton;

  /// No description provided for @backToHomeButton.
  ///
  /// In ar, this message translates to:
  /// **'العودة للرئيسية'**
  String get backToHomeButton;

  /// No description provided for @statusSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم الاستلام'**
  String get statusSubmitted;

  /// No description provided for @statusUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير معروف'**
  String get statusUnknown;

  /// No description provided for @myRequestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequestsTitle;

  /// No description provided for @myRequestsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم ترسل أي طلب بعد. اختر خدمة لتبدأ.'**
  String get myRequestsEmpty;

  /// No description provided for @loadMoreButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض المزيد'**
  String get loadMoreButton;

  /// No description provided for @submittedOn.
  ///
  /// In ar, this message translates to:
  /// **'أُرسل في {date}'**
  String submittedOn(String date);

  /// No description provided for @requestDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الطلب'**
  String get requestDetailTitle;

  /// No description provided for @timelineTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الطلب'**
  String get timelineTitle;

  /// No description provided for @photoLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تحميل الصورة'**
  String get photoLoadFailed;

  /// No description provided for @requestsCustomerOnly.
  ///
  /// In ar, this message translates to:
  /// **'طلب الخدمات متاح لحسابات العملاء فقط.'**
  String get requestsCustomerOnly;

  /// No description provided for @errorServiceNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'هذه الخدمة غير متاحة حاليًا.'**
  String get errorServiceNotAvailable;

  /// No description provided for @errorAreaNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'هذه المنطقة غير مخدومة حاليًا.'**
  String get errorAreaNotAvailable;

  /// No description provided for @errorLocationOutOfArea.
  ///
  /// In ar, this message translates to:
  /// **'الموقع خارج نطاق الخدمة.'**
  String get errorLocationOutOfArea;

  /// No description provided for @errorInvalidSchedule.
  ///
  /// In ar, this message translates to:
  /// **'هذا الموعد لم يعد متاحًا. اختر موعدًا آخر.'**
  String get errorInvalidSchedule;

  /// No description provided for @errorTooManyOpenRequests.
  ///
  /// In ar, this message translates to:
  /// **'لديك طلبات مفتوحة كثيرة. انتظر حتى تُنجز قبل إرسال طلب جديد.'**
  String get errorTooManyOpenRequests;

  /// No description provided for @errorMediaInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أحد الملفات لم يعد صالحًا. احذفه وأعد إضافته.'**
  String get errorMediaInvalid;

  /// No description provided for @errorFileTooLarge.
  ///
  /// In ar, this message translates to:
  /// **'الملف كبير جدًا.'**
  String get errorFileTooLarge;

  /// No description provided for @errorUnsupportedFile.
  ///
  /// In ar, this message translates to:
  /// **'نوع الملف غير مدعوم. استخدم صورة JPG أو PNG.'**
  String get errorUnsupportedFile;

  /// No description provided for @errorMediaUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'رفع الملفات غير متاح حاليًا.'**
  String get errorMediaUnavailable;

  /// No description provided for @errorMediaPendingLimit.
  ///
  /// In ar, this message translates to:
  /// **'لديك ملفات مرفوعة كثيرة لم تُستخدم بعد. احذف بعضها أولًا.'**
  String get errorMediaPendingLimit;

  /// No description provided for @errorAddressNotFound.
  ///
  /// In ar, this message translates to:
  /// **'هذا العنوان لم يعد موجودًا. اختر عنوانًا آخر.'**
  String get errorAddressNotFound;

  /// No description provided for @errorAddressLimit.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى الحد الأقصى من العناوين المحفوظة.'**
  String get errorAddressLimit;

  /// No description provided for @errorValidation.
  ///
  /// In ar, this message translates to:
  /// **'بعض البيانات غير صحيحة. راجعها وحاول مرة أخرى.'**
  String get errorValidation;

  /// No description provided for @errorForbidden.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك صلاحية لهذا الإجراء.'**
  String get errorForbidden;

  /// No description provided for @errorApplicationAlreadySubmitted.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام قيد المراجعة بالفعل.'**
  String get errorApplicationAlreadySubmitted;

  /// No description provided for @errorApplicationStateConflict.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالة الطلب. حدّث الصفحة.'**
  String get errorApplicationStateConflict;

  /// No description provided for @errorCategoryNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'أحد التخصصات لم يعد متاحًا.'**
  String get errorCategoryNotAvailable;

  /// No description provided for @errorDocumentsRequired.
  ///
  /// In ar, this message translates to:
  /// **'{min, plural, =1{أرفق مستندًا واحدًا على الأقل.} =2{أرفق مستندين على الأقل.} few{أرفق {min} مستندات على الأقل.} other{أرفق {min} مستندًا على الأقل.}}'**
  String errorDocumentsRequired(int min);

  /// No description provided for @errorCannotReviewOwn.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكنك مراجعة طلبك الشخصي.'**
  String get errorCannotReviewOwn;

  /// No description provided for @myRequestsEntry.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get myRequestsEntry;

  /// No description provided for @technicianEntryApply.
  ///
  /// In ar, this message translates to:
  /// **'انضم كفني'**
  String get technicianEntryApply;

  /// No description provided for @technicianEntryStatus.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام كفني'**
  String get technicianEntryStatus;

  /// No description provided for @adminReviewEntry.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة طلبات الفنيين'**
  String get adminReviewEntry;

  /// No description provided for @technicianApplyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام كفني'**
  String get technicianApplyTitle;

  /// No description provided for @technicianApplyIntro.
  ///
  /// In ar, this message translates to:
  /// **'أرسل بياناتك لتراجعها الإدارة. لن تتلقى أي طلبات عمل قبل اعتماد حسابك.'**
  String get technicianApplyIntro;

  /// No description provided for @fullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullNameLabel;

  /// No description provided for @fullNameInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل اسمك الكامل بالحروف.'**
  String get fullNameInvalid;

  /// No description provided for @yearsLabel.
  ///
  /// In ar, this message translates to:
  /// **'سنوات الخبرة (اختياري)'**
  String get yearsLabel;

  /// No description provided for @yearsInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقمًا من 0 إلى 60.'**
  String get yearsInvalid;

  /// No description provided for @bioLabel.
  ///
  /// In ar, this message translates to:
  /// **'نبذة عن خبرتك (اختياري)'**
  String get bioLabel;

  /// No description provided for @specialtiesTitle.
  ///
  /// In ar, this message translates to:
  /// **'التخصصات'**
  String get specialtiesTitle;

  /// No description provided for @specialtiesRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر تخصصًا واحدًا على الأقل.'**
  String get specialtiesRequired;

  /// No description provided for @serviceAreasTitle.
  ///
  /// In ar, this message translates to:
  /// **'مناطق العمل'**
  String get serviceAreasTitle;

  /// No description provided for @serviceAreasRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر منطقة واحدة على الأقل.'**
  String get serviceAreasRequired;

  /// No description provided for @documentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مستندات التحقق'**
  String get documentsTitle;

  /// No description provided for @documentsOptionalHelp.
  ///
  /// In ar, this message translates to:
  /// **'المستندات المطلوبة لم تُحدَّد بعد. أرفق ما يثبت هويتك أو خبرتك إن وُجد.'**
  String get documentsOptionalHelp;

  /// No description provided for @documentsMinHelp.
  ///
  /// In ar, this message translates to:
  /// **'{min, plural, =1{أرفق مستندًا واحدًا على الأقل.} =2{أرفق مستندين على الأقل.} few{أرفق {min} مستندات على الأقل.} other{أرفق {min} مستندًا على الأقل.}}'**
  String documentsMinHelp(int min);

  /// No description provided for @documentsPrivacy.
  ///
  /// In ar, this message translates to:
  /// **'المستندات خاصة، ولا يطّلع عليها إلا فريق المراجعة.'**
  String get documentsPrivacy;

  /// No description provided for @documentKindLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع المستند'**
  String get documentKindLabel;

  /// No description provided for @documentKindIdentity.
  ///
  /// In ar, this message translates to:
  /// **'إثبات الهوية'**
  String get documentKindIdentity;

  /// No description provided for @documentKindQualification.
  ///
  /// In ar, this message translates to:
  /// **'شهادة أو خبرة'**
  String get documentKindQualification;

  /// No description provided for @documentKindOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get documentKindOther;

  /// No description provided for @documentNumber.
  ///
  /// In ar, this message translates to:
  /// **'مستند {number}'**
  String documentNumber(int number);

  /// No description provided for @documentRemove.
  ///
  /// In ar, this message translates to:
  /// **'حذف المستند'**
  String get documentRemove;

  /// No description provided for @documentLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت إلى الحد الأقصى من المستندات.'**
  String get documentLimitReached;

  /// No description provided for @submitApplicationButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب الانضمام'**
  String get submitApplicationButton;

  /// No description provided for @resubmitApplicationButton.
  ///
  /// In ar, this message translates to:
  /// **'تعديل وإعادة الإرسال'**
  String get resubmitApplicationButton;

  /// No description provided for @applicationSubmittedMessage.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلبك للمراجعة.'**
  String get applicationSubmittedMessage;

  /// No description provided for @applicationStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام كفني'**
  String get applicationStatusTitle;

  /// No description provided for @verificationPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get verificationPending;

  /// No description provided for @verificationPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'تراجع الإدارة بياناتك، وستظهر النتيجة هنا.'**
  String get verificationPendingBody;

  /// No description provided for @verificationApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get verificationApproved;

  /// No description provided for @verificationApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد حسابك كفني. استقبال طلبات العمل سيتاح في تحديث قادم.'**
  String get verificationApprovedBody;

  /// No description provided for @verificationRejected.
  ///
  /// In ar, this message translates to:
  /// **'لم يُقبل'**
  String get verificationRejected;

  /// No description provided for @verificationRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تعديل بياناتك وإعادة الإرسال.'**
  String get verificationRejectedBody;

  /// No description provided for @verificationRejectedFinal.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن إعادة الإرسال حاليًا. تواصل مع الدعم.'**
  String get verificationRejectedFinal;

  /// No description provided for @verificationSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get verificationSuspended;

  /// No description provided for @verificationSuspendedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف حسابك كفني مؤقتًا. تواصل مع الدعم.'**
  String get verificationSuspendedBody;

  /// No description provided for @decisionReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'سبب القرار'**
  String get decisionReasonLabel;

  /// No description provided for @adminApplicationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الفنيين'**
  String get adminApplicationsTitle;

  /// No description provided for @adminApplicationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بهذه الحالة.'**
  String get adminApplicationsEmpty;

  /// No description provided for @adminApplicationMeta.
  ///
  /// In ar, this message translates to:
  /// **'التخصصات: {specialties} · المناطق: {areas} · المستندات: {documents}'**
  String adminApplicationMeta(int specialties, int areas, int documents);

  /// No description provided for @adminApplicantPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get adminApplicantPhone;

  /// No description provided for @yearsValue.
  ///
  /// In ar, this message translates to:
  /// **'سنوات الخبرة: {years}'**
  String yearsValue(int years);

  /// No description provided for @documentsNone.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مستندات'**
  String get documentsNone;

  /// No description provided for @pdfDocumentLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملف PDF (المعاينة غير متاحة في التطبيق)'**
  String get pdfDocumentLabel;

  /// No description provided for @adminHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل المراجعة'**
  String get adminHistoryTitle;

  /// No description provided for @historySubmitted.
  ///
  /// In ar, this message translates to:
  /// **'أرسل الطلب'**
  String get historySubmitted;

  /// No description provided for @historyResubmitted.
  ///
  /// In ar, this message translates to:
  /// **'أعاد الإرسال'**
  String get historyResubmitted;

  /// No description provided for @historyApproved.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get historyApproved;

  /// No description provided for @historyRejected.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get historyRejected;

  /// No description provided for @historySuspended.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get historySuspended;

  /// No description provided for @adminApproveButton.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد'**
  String get adminApproveButton;

  /// No description provided for @adminRejectButton.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get adminRejectButton;

  /// No description provided for @adminSuspendButton.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get adminSuspendButton;

  /// No description provided for @adminReinstateButton.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التفعيل'**
  String get adminReinstateButton;

  /// No description provided for @adminApproveTitle.
  ///
  /// In ar, this message translates to:
  /// **'اعتماد الفني؟'**
  String get adminApproveTitle;

  /// No description provided for @adminApproveBody.
  ///
  /// In ar, this message translates to:
  /// **'سيصبح الحساب حساب فني معتمد.'**
  String get adminApproveBody;

  /// No description provided for @adminRejectTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفض الطلب'**
  String get adminRejectTitle;

  /// No description provided for @adminSuspendTitle.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف الفني'**
  String get adminSuspendTitle;

  /// No description provided for @adminNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة داخلية (اختياري)'**
  String get adminNoteLabel;

  /// No description provided for @adminReasonLabel.
  ///
  /// In ar, this message translates to:
  /// **'السبب (يظهر لمقدم الطلب)'**
  String get adminReasonLabel;

  /// No description provided for @adminReasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سببًا من 3 أحرف على الأقل.'**
  String get adminReasonRequired;

  /// No description provided for @adminDecisionSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ القرار.'**
  String get adminDecisionSaved;
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
