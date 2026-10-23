// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'صيانتك';

  @override
  String get homeHeadline => 'ما الخدمة التي تحتاجها؟';

  @override
  String get homeSubtitle => 'اختر نوع الخدمة واطّلع على التفاصيل قبل الطلب.';

  @override
  String get categoriesTitle => 'الخدمات';

  @override
  String get switchLanguage => 'English';

  @override
  String get switchLanguageTooltip => 'تغيير اللغة إلى الإنجليزية';

  @override
  String get accountTooltip => 'حسابي';

  @override
  String get signInTooltip => 'تسجيل الدخول';

  @override
  String servicesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمة',
      many: '$count خدمة',
      few: '$count خدمات',
      two: 'خدمتان',
      one: 'خدمة واحدة',
      zero: 'لا توجد خدمات',
    );
    return '$_temp0';
  }

  @override
  String get sampleDataBadge => 'بيانات تجريبية';

  @override
  String get sampleDataNotice => 'هذه بيانات تجريبية للعرض فقط ولم تُعتمد بعد.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get retry => 'حاول مرة أخرى';

  @override
  String get emptyCategories => 'لا توجد خدمات متاحة حاليًا. حاول لاحقًا.';

  @override
  String get emptyServices => 'لا توجد خدمات متاحة في هذا القسم حاليًا.';

  @override
  String get errorLoadTitle => 'تعذّر تحميل البيانات';

  @override
  String get errorNotFound => 'العنصر المطلوب غير موجود أو لم يعد متاحًا.';

  @override
  String get errorNetwork =>
      'تعذّر الاتصال. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';

  @override
  String get errorGeneric => 'حدث خطأ غير متوقع. حاول مرة أخرى.';

  @override
  String get priceInspectionRequired => 'السعر يُحدَّد بعد المعاينة';

  @override
  String get priceInspectionExplanation =>
      'لا يوجد سعر تقديري موثوق لهذه الخدمة. سيعاين الفني المشكلة ويرسل لك عرض سعر مفصّل توافق عليه قبل بدء العمل.';

  @override
  String priceIndicativeRange(String min, String max) {
    return 'سعر تقديري: $min – $max';
  }

  @override
  String get priceIndicativeExplanation =>
      'السعر النهائي يُحدَّد بعد المعاينة ويحتاج موافقتك قبل بدء العمل.';

  @override
  String get pricingTitle => 'التسعير';

  @override
  String get aboutServiceTitle => 'عن الخدمة';

  @override
  String get requestServiceButton => 'اطلب الخدمة';

  @override
  String get requestComingSoon => 'تقديم طلبات الخدمة سيتاح قريبًا.';

  @override
  String get signInToRequest => 'سجّل الدخول لطلب الخدمة';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get signInSubtitle =>
      'أدخل رقم الموبايل وسنرسل إليك رمز تحقق في رسالة نصية.';

  @override
  String get phoneLabel => 'رقم الموبايل';

  @override
  String get phoneHint => '01XXXXXXXXX';

  @override
  String get phoneInvalid => 'أدخل رقم موبايل مصري صحيح (مثال: 01012345678).';

  @override
  String get sendCodeButton => 'إرسال الرمز';

  @override
  String get otpTitle => 'أدخل رمز التحقق';

  @override
  String otpSubtitle(int length, String phone) {
    return 'أرسلنا رمزًا من $length أرقام إلى $phone.';
  }

  @override
  String get otpLabel => 'رمز التحقق';

  @override
  String otpInvalidFormat(int length) {
    return 'أدخل الرمز كاملًا ($length أرقام).';
  }

  @override
  String get verifyButton => 'تأكيد';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ث';
  }

  @override
  String get resendButton => 'إعادة إرسال الرمز';

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String get codeResent => 'تم إرسال رمز جديد.';

  @override
  String devCodeBanner(String code) {
    return 'وضع التطوير فقط — لم تُرسل رسالة. الرمز: $code';
  }

  @override
  String errorOtpInvalid(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'تبقّت $attempts محاولة.',
      few: 'تبقّت $attempts محاولات.',
      two: 'تبقّت محاولتان.',
      one: 'تبقّت محاولة واحدة.',
      zero: 'لا توجد محاولات متبقية.',
    );
    return 'الرمز غير صحيح. $_temp0';
  }

  @override
  String get errorOtpInvalidNoCount => 'الرمز غير صحيح.';

  @override
  String get errorOtpExpired => 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.';

  @override
  String get errorOtpTooManyAttempts =>
      'محاولات خاطئة كثيرة. اطلب رمزًا جديدًا.';

  @override
  String errorResendTooSoon(int seconds) {
    return 'انتظر $seconds ثانية قبل طلب رمز جديد.';
  }

  @override
  String get errorOtpRateLimited =>
      'طلبت رموزًا كثيرة لهذا الرقم. حاول مرة أخرى بعد قليل.';

  @override
  String get errorRateLimited => 'طلبات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';

  @override
  String get errorOtpUnavailable => 'تسجيل الدخول برسائل SMS غير متاح حاليًا.';

  @override
  String get errorOtpDeliveryFailed => 'تعذّر إرسال الرمز. حاول مرة أخرى.';

  @override
  String get errorAccountSuspended => 'تم إيقاف هذا الحساب. تواصل مع الدعم.';

  @override
  String get errorSessionExpired => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get signedInWelcome => 'أهلًا بك! تم تسجيل الدخول.';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get profileNameLabel => 'الاسم';

  @override
  String get profileNameHint => 'اكتب اسمك';

  @override
  String get profileNameInvalid => 'أدخل اسمًا من حرفين على الأقل.';

  @override
  String get profilePhoneLabel => 'رقم الموبايل';

  @override
  String get profileRoleLabel => 'نوع الحساب';

  @override
  String get roleCustomer => 'عميل';

  @override
  String get roleTechnician => 'فني';

  @override
  String get roleAdmin => 'إدارة';

  @override
  String get saveButton => 'حفظ';

  @override
  String get profileSaved => 'تم حفظ البيانات.';

  @override
  String get signOutButton => 'تسجيل الخروج';
}
