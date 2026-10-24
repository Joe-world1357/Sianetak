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

  /// No description provided for @servicesCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد خدمات} =1{خدمة واحدة} =2{خدمتان} few{{count} خدمات} many{{count} خدمة} other{{count} خدمة}}'**
  String servicesCount(int count);

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
  /// **'تعذّر الوصول إلى البيانات. حاول مرة أخرى.'**
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

  /// No description provided for @signInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بعودتك. ادخل برقم موبايلك وكلمة المرور.'**
  String get signInSubtitle;

  /// No description provided for @errorSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت جلستك. سجّل الدخول مرة أخرى.'**
  String get errorSessionExpired;

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
  /// **'بانتظار فني'**
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

  /// No description provided for @technicianEntryStatus.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام كفني'**
  String get technicianEntryStatus;

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
  /// **'يراجع المسؤول بياناتك، وستظهر النتيجة هنا. يمكنك الدخول لاحقاً لمتابعتها.'**
  String get verificationPendingBody;

  /// No description provided for @verificationApproved.
  ///
  /// In ar, this message translates to:
  /// **'معتمد'**
  String get verificationApproved;

  /// No description provided for @verificationApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد حسابك كفني. ستجد عروض العمل والأعمال المسندة إليك في الشاشة الرئيسية.'**
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
  /// **'لا يمكن إعادة الإرسال حالياً. تواصل مع المسؤول.'**
  String get verificationRejectedFinal;

  /// No description provided for @verificationSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get verificationSuspended;

  /// No description provided for @verificationSuspendedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف حسابك كفني مؤقتاً. تواصل مع المسؤول.'**
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

  /// No description provided for @statusUnmatched.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الإدارة'**
  String get statusUnmatched;

  /// No description provided for @statusAssigned.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين فني'**
  String get statusAssigned;

  /// No description provided for @statusEnRoute.
  ///
  /// In ar, this message translates to:
  /// **'الفني في الطريق'**
  String get statusEnRoute;

  /// No description provided for @statusArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل الفني'**
  String get statusArrived;

  /// No description provided for @statusQuoted.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار موافقة السعر'**
  String get statusQuoted;

  /// No description provided for @statusQuoteRejected.
  ///
  /// In ar, this message translates to:
  /// **'العرض مرفوض'**
  String get statusQuoteRejected;

  /// No description provided for @statusInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التنفيذ'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get statusCancelled;

  /// No description provided for @homeGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلًا {name} 👋'**
  String homeGreeting(String name);

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلباتي'**
  String get tabRequests;

  /// No description provided for @tabNotifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get tabNotifications;

  /// No description provided for @tabAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabAccount;

  /// No description provided for @tabOffers.
  ///
  /// In ar, this message translates to:
  /// **'العروض'**
  String get tabOffers;

  /// No description provided for @tabJobs.
  ///
  /// In ar, this message translates to:
  /// **'أعمالي'**
  String get tabJobs;

  /// No description provided for @tabDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التحكم'**
  String get tabDashboard;

  /// No description provided for @tabTechnicians.
  ///
  /// In ar, this message translates to:
  /// **'الفنيون'**
  String get tabTechnicians;

  /// No description provided for @languageSetting.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageSetting;

  /// No description provided for @technicianCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الفني'**
  String get technicianCardTitle;

  /// No description provided for @customerCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'العميل'**
  String get customerCardTitle;

  /// No description provided for @ratingNone.
  ///
  /// In ar, this message translates to:
  /// **'لا تقييمات بعد'**
  String get ratingNone;

  /// No description provided for @ratingSummary.
  ///
  /// In ar, this message translates to:
  /// **'{avg} ({count})'**
  String ratingSummary(String avg, int count);

  /// No description provided for @ratingStars.
  ///
  /// In ar, this message translates to:
  /// **'{stars} من ٥ نجوم'**
  String ratingStars(int stars);

  /// No description provided for @ratingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييمك'**
  String get ratingTitle;

  /// No description provided for @etaEstimate.
  ///
  /// In ar, this message translates to:
  /// **'الوصول المتوقع خلال ٢٠–٣٠ دقيقة تقريبًا'**
  String get etaEstimate;

  /// No description provided for @chatOpenButton.
  ///
  /// In ar, this message translates to:
  /// **'محادثة الطلب'**
  String get chatOpenButton;

  /// No description provided for @chatViewButton.
  ///
  /// In ar, this message translates to:
  /// **'عرض المحادثة'**
  String get chatViewButton;

  /// No description provided for @chatTitle.
  ///
  /// In ar, this message translates to:
  /// **'المحادثة'**
  String get chatTitle;

  /// No description provided for @chatEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا رسائل بعد. اكتب أول رسالة.'**
  String get chatEmpty;

  /// No description provided for @chatHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة…'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get chatSend;

  /// No description provided for @chatReadOnly.
  ///
  /// In ar, this message translates to:
  /// **'المحادثة للعرض فقط.'**
  String get chatReadOnly;

  /// No description provided for @paymentTitle.
  ///
  /// In ar, this message translates to:
  /// **'الدفع'**
  String get paymentTitle;

  /// No description provided for @paymentCashCollected.
  ///
  /// In ar, this message translates to:
  /// **'تم التحصيل نقدًا'**
  String get paymentCashCollected;

  /// No description provided for @paymentCommission.
  ///
  /// In ar, this message translates to:
  /// **'عمولة المنصة'**
  String get paymentCommission;

  /// No description provided for @paymentRecordedAt.
  ///
  /// In ar, this message translates to:
  /// **'وقت التسجيل'**
  String get paymentRecordedAt;

  /// No description provided for @cancelReasonTitle.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء'**
  String get cancelReasonTitle;

  /// No description provided for @addressHiddenUntilAccepted.
  ///
  /// In ar, this message translates to:
  /// **'يظهر العنوان بالتفصيل بعد قبول الطلب.'**
  String get addressHiddenUntilAccepted;

  /// No description provided for @byOperations.
  ///
  /// In ar, this message translates to:
  /// **'بواسطة الإدارة'**
  String get byOperations;

  /// No description provided for @quoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرض السعر'**
  String get quoteTitle;

  /// No description provided for @quotePending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار الموافقة'**
  String get quotePending;

  /// No description provided for @quoteApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة'**
  String get quoteApproved;

  /// No description provided for @quoteRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get quoteRejected;

  /// No description provided for @journeyStep.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة {step} من {total}'**
  String journeyStep(int step, int total);

  /// No description provided for @cancelRequestButton.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الطلب'**
  String get cancelRequestButton;

  /// No description provided for @cancelSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'لماذا تريد إلغاء الطلب؟'**
  String get cancelSheetTitle;

  /// No description provided for @cancelReasonChangedMind.
  ///
  /// In ar, this message translates to:
  /// **'لم أعد بحاجة للخدمة'**
  String get cancelReasonChangedMind;

  /// No description provided for @cancelReasonFixed.
  ///
  /// In ar, this message translates to:
  /// **'تم حل المشكلة'**
  String get cancelReasonFixed;

  /// No description provided for @cancelReasonTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الانتظار طويل'**
  String get cancelReasonTooLong;

  /// No description provided for @cancelReasonOther.
  ///
  /// In ar, this message translates to:
  /// **'سبب آخر'**
  String get cancelReasonOther;

  /// No description provided for @requestCancelledToast.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب.'**
  String get requestCancelledToast;

  /// No description provided for @customerSearchingTitle.
  ///
  /// In ar, this message translates to:
  /// **'نبحث لك عن فني مناسب'**
  String get customerSearchingTitle;

  /// No description provided for @customerSearchingBody.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا طلبك للفنيين المعتمدين في منطقتك. ستصلك رسالة فور قبول أحدهم.'**
  String get customerSearchingBody;

  /// No description provided for @customerUnmatchedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم يقبل أي فني بعد'**
  String get customerUnmatchedTitle;

  /// No description provided for @customerUnmatchedBody.
  ///
  /// In ar, this message translates to:
  /// **'فريق التشغيل سيعيّن لك فنيًا يدويًا في أقرب وقت.'**
  String get customerUnmatchedBody;

  /// No description provided for @customerAssignedTitle.
  ///
  /// In ar, this message translates to:
  /// **'فنيك جاهز'**
  String get customerAssignedTitle;

  /// No description provided for @customerAssignedBody.
  ///
  /// In ar, this message translates to:
  /// **'سيعاين الفني المشكلة ثم يرسل لك عرض سعر قبل بدء أي عمل.'**
  String get customerAssignedBody;

  /// No description provided for @customerQuoteTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرض سعر: {amount}'**
  String customerQuoteTitle(String amount);

  /// No description provided for @customerQuoteBody.
  ///
  /// In ar, this message translates to:
  /// **'لن يبدأ العمل إلا بعد موافقتك. الدفع نقدًا عند الانتهاء.'**
  String get customerQuoteBody;

  /// No description provided for @customerQuoteRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفضت عرض السعر'**
  String get customerQuoteRejectedTitle;

  /// No description provided for @customerQuoteRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكن للفني إرسال عرض جديد، أو يمكنك إلغاء الطلب.'**
  String get customerQuoteRejectedBody;

  /// No description provided for @customerInProgressTitle.
  ///
  /// In ar, this message translates to:
  /// **'العمل جارٍ الآن'**
  String get customerInProgressTitle;

  /// No description provided for @customerInProgressBody.
  ///
  /// In ar, this message translates to:
  /// **'سيؤكد الفني الانتهاء وتحصيل المبلغ المتفق عليه.'**
  String get customerInProgressBody;

  /// No description provided for @customerCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الخدمة'**
  String get customerCompletedTitle;

  /// No description provided for @customerCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'شاركنا رأيك في الفني لمساعدة الآخرين.'**
  String get customerCompletedBody;

  /// No description provided for @approveQuoteButton.
  ///
  /// In ar, this message translates to:
  /// **'الموافقة على السعر'**
  String get approveQuoteButton;

  /// No description provided for @rejectQuoteButton.
  ///
  /// In ar, this message translates to:
  /// **'رفض العرض'**
  String get rejectQuoteButton;

  /// No description provided for @quoteApprovedToast.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة. أبلغنا الفني ليبدأ العمل.'**
  String get quoteApprovedToast;

  /// No description provided for @rateButton.
  ///
  /// In ar, this message translates to:
  /// **'قيّم الخدمة'**
  String get rateButton;

  /// No description provided for @rateSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف كانت الخدمة؟'**
  String get rateSheetTitle;

  /// No description provided for @rateCommentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعليق (اختياري)'**
  String get rateCommentLabel;

  /// No description provided for @rateSubmitButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التقييم'**
  String get rateSubmitButton;

  /// No description provided for @ratingThanks.
  ///
  /// In ar, this message translates to:
  /// **'شكرًا لتقييمك!'**
  String get ratingThanks;

  /// No description provided for @offerForYouTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد لك'**
  String get offerForYouTitle;

  /// No description provided for @offerExpiresIn.
  ///
  /// In ar, this message translates to:
  /// **'{minutes, plural, =0{ينتهي العرض الآن} =1{ينتهي خلال دقيقة} =2{ينتهي خلال دقيقتين} few{ينتهي خلال {minutes} دقائق} other{ينتهي خلال {minutes} دقيقة}}'**
  String offerExpiresIn(int minutes);

  /// No description provided for @acceptOfferButton.
  ///
  /// In ar, this message translates to:
  /// **'قبول الطلب'**
  String get acceptOfferButton;

  /// No description provided for @declineOfferButton.
  ///
  /// In ar, this message translates to:
  /// **'اعتذار'**
  String get declineOfferButton;

  /// No description provided for @offerAcceptedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول الطلب وأبلغنا العميل.'**
  String get offerAcceptedToast;

  /// No description provided for @techAssignedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلب لك'**
  String get techAssignedTitle;

  /// No description provided for @techAssignedBody.
  ///
  /// In ar, this message translates to:
  /// **'أبلغ العميل عندما تتحرك إليه.'**
  String get techAssignedBody;

  /// No description provided for @onMyWayButton.
  ///
  /// In ar, this message translates to:
  /// **'أنا في الطريق'**
  String get onMyWayButton;

  /// No description provided for @arrivedButton.
  ///
  /// In ar, this message translates to:
  /// **'وصلت'**
  String get arrivedButton;

  /// No description provided for @customerNotifiedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم إبلاغ العميل.'**
  String get customerNotifiedToast;

  /// No description provided for @techQuoteNeededTitle.
  ///
  /// In ar, this message translates to:
  /// **'عاين وأرسل عرض السعر'**
  String get techQuoteNeededTitle;

  /// No description provided for @techQuoteRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'رفض العميل العرض'**
  String get techQuoteRejectedTitle;

  /// No description provided for @techQuoteNeededBody.
  ///
  /// In ar, this message translates to:
  /// **'لا يبدأ العمل قبل موافقة العميل على السعر.'**
  String get techQuoteNeededBody;

  /// No description provided for @sendQuoteButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال عرض السعر'**
  String get sendQuoteButton;

  /// No description provided for @techAwaitingApprovalTitle.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار موافقة العميل'**
  String get techAwaitingApprovalTitle;

  /// No description provided for @techAwaitingApprovalBody.
  ///
  /// In ar, this message translates to:
  /// **'سنبلغك فور الموافقة على العرض أو رفضه.'**
  String get techAwaitingApprovalBody;

  /// No description provided for @techWorkingTitle.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة، ابدأ العمل'**
  String get techWorkingTitle;

  /// No description provided for @techWorkingBody.
  ///
  /// In ar, this message translates to:
  /// **'عند الانتهاء حصّل {amount} نقدًا وأكّد الإنجاز.'**
  String techWorkingBody(String amount);

  /// No description provided for @completeJobButton.
  ///
  /// In ar, this message translates to:
  /// **'تم الانتهاء وتحصيل المبلغ'**
  String get completeJobButton;

  /// No description provided for @completeJobTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الانتهاء'**
  String get completeJobTitle;

  /// No description provided for @completeJobBody.
  ///
  /// In ar, this message translates to:
  /// **'هل انتهى العمل وتم تحصيل {amount} نقدًا من العميل؟'**
  String completeJobBody(String amount);

  /// No description provided for @jobCompletedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الإنجاز والدفع.'**
  String get jobCompletedToast;

  /// No description provided for @quoteSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'عرض السعر'**
  String get quoteSheetTitle;

  /// No description provided for @quoteSheetHint.
  ///
  /// In ar, this message translates to:
  /// **'أدخل السعر الإجمالي (مصنعية وقطع غيار) بعد المعاينة.'**
  String get quoteSheetHint;

  /// No description provided for @quoteAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get quoteAmountLabel;

  /// No description provided for @quoteAmountInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغًا صحيحًا.'**
  String get quoteAmountInvalid;

  /// No description provided for @quoteNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل العمل (اختياري)'**
  String get quoteNoteLabel;

  /// No description provided for @currencyEgpShort.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get currencyEgpShort;

  /// No description provided for @quoteSentToast.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال العرض للعميل.'**
  String get quoteSentToast;

  /// No description provided for @adminSearchingTitle.
  ///
  /// In ar, this message translates to:
  /// **'العروض مرسلة للفنيين'**
  String get adminSearchingTitle;

  /// No description provided for @adminUnmatchedTitle.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج تعيينًا يدويًا'**
  String get adminUnmatchedTitle;

  /// No description provided for @adminAssignBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تعيين فني معتمد يغطي الخدمة والمنطقة.'**
  String get adminAssignBody;

  /// No description provided for @assignTechnicianButton.
  ///
  /// In ar, this message translates to:
  /// **'تعيين فني'**
  String get assignTechnicianButton;

  /// No description provided for @assignSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر فنيًا'**
  String get assignSheetTitle;

  /// No description provided for @assignNoneEligible.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فني معتمد يغطي هذه الخدمة والمنطقة.'**
  String get assignNoneEligible;

  /// No description provided for @assignedToast.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين الفني.'**
  String get assignedToast;

  /// No description provided for @offersTitle.
  ///
  /// In ar, this message translates to:
  /// **'عروض العمل'**
  String get offersTitle;

  /// No description provided for @offersIntro.
  ///
  /// In ar, this message translates to:
  /// **'طلبات تناسب تخصصك ومنطقتك. أول من يقبل يحصل على الطلب.'**
  String get offersIntro;

  /// No description provided for @offersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا عروض جديدة الآن. سنبلغك عند وصول طلب.'**
  String get offersEmpty;

  /// No description provided for @myJobsTitle.
  ///
  /// In ar, this message translates to:
  /// **'أعمالي'**
  String get myJobsTitle;

  /// No description provided for @jobsActiveTab.
  ///
  /// In ar, this message translates to:
  /// **'الحالية'**
  String get jobsActiveTab;

  /// No description provided for @jobsHistoryTab.
  ///
  /// In ar, this message translates to:
  /// **'السابقة'**
  String get jobsHistoryTab;

  /// No description provided for @jobsEmptyActive.
  ///
  /// In ar, this message translates to:
  /// **'لا أعمال حالية. اقبل عرضًا لتبدأ.'**
  String get jobsEmptyActive;

  /// No description provided for @jobsEmptyHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا أعمال منتهية بعد.'**
  String get jobsEmptyHistory;

  /// No description provided for @earningsTitle.
  ///
  /// In ar, this message translates to:
  /// **'صافي أرباحك'**
  String get earningsTitle;

  /// No description provided for @earningsNetHint.
  ///
  /// In ar, this message translates to:
  /// **'بعد خصم عمولة المنصة (١٠٪ — قيمة مقترحة)'**
  String get earningsNetHint;

  /// No description provided for @earningsJobs.
  ///
  /// In ar, this message translates to:
  /// **'أعمال'**
  String get earningsJobs;

  /// No description provided for @earningsCollected.
  ///
  /// In ar, this message translates to:
  /// **'المحصّل'**
  String get earningsCollected;

  /// No description provided for @earningsCommission.
  ///
  /// In ar, this message translates to:
  /// **'العمولة'**
  String get earningsCommission;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا إشعارات بعد.'**
  String get notificationsEmpty;

  /// No description provided for @markAllRead.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الكل كمقروء'**
  String get markAllRead;

  /// No description provided for @ntfNewOffer.
  ///
  /// In ar, this message translates to:
  /// **'طلب جديد يناسبك {ref}'**
  String ntfNewOffer(String ref);

  /// No description provided for @ntfAssignedByAdmin.
  ///
  /// In ar, this message translates to:
  /// **'عيّنتك الإدارة على الطلب {ref}'**
  String ntfAssignedByAdmin(String ref);

  /// No description provided for @ntfAssigned.
  ///
  /// In ar, this message translates to:
  /// **'تم تعيين فني لطلبك {ref}'**
  String ntfAssigned(String ref);

  /// No description provided for @ntfEnRoute.
  ///
  /// In ar, this message translates to:
  /// **'الفني في الطريق إليك {ref}'**
  String ntfEnRoute(String ref);

  /// No description provided for @ntfArrived.
  ///
  /// In ar, this message translates to:
  /// **'وصل الفني {ref}'**
  String ntfArrived(String ref);

  /// No description provided for @ntfQuoted.
  ///
  /// In ar, this message translates to:
  /// **'وصلك عرض سعر للطلب {ref}'**
  String ntfQuoted(String ref);

  /// No description provided for @ntfQuoteApproved.
  ///
  /// In ar, this message translates to:
  /// **'وافق العميل على عرضك {ref}'**
  String ntfQuoteApproved(String ref);

  /// No description provided for @ntfQuoteRejected.
  ///
  /// In ar, this message translates to:
  /// **'رفض العميل عرضك {ref}'**
  String ntfQuoteRejected(String ref);

  /// No description provided for @ntfCompleted.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت الخدمة {ref}. قيّم الفني'**
  String ntfCompleted(String ref);

  /// No description provided for @ntfRated.
  ///
  /// In ar, this message translates to:
  /// **'وصلك تقييم جديد {ref}'**
  String ntfRated(String ref);

  /// No description provided for @ntfMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة جديدة بخصوص {ref}'**
  String ntfMessage(String ref);

  /// No description provided for @ntfCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الطلب {ref}'**
  String ntfCancelled(String ref);

  /// No description provided for @ntfUnmatched.
  ///
  /// In ar, this message translates to:
  /// **'الطلب {ref} يحتاج تعيين فني'**
  String ntfUnmatched(String ref);

  /// No description provided for @ntfApplicationSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'طلب انضمام فني جديد بانتظار المراجعة'**
  String get ntfApplicationSubmitted;

  /// No description provided for @ntfApplicationApproved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على طلب انضمامك كفني'**
  String get ntfApplicationApproved;

  /// No description provided for @ntfApplicationRejected.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم الموافقة على طلب انضمامك'**
  String get ntfApplicationRejected;

  /// No description provided for @ntfApplicationSuspended.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف حسابك كفني مؤقتًا'**
  String get ntfApplicationSuspended;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'لوحة التشغيل'**
  String get adminDashboardTitle;

  /// No description provided for @kpiNeedsAttention.
  ///
  /// In ar, this message translates to:
  /// **'بحاجة لمتابعة'**
  String get kpiNeedsAttention;

  /// No description provided for @kpiInProgress.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get kpiInProgress;

  /// No description provided for @kpiCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة'**
  String get kpiCompleted;

  /// No description provided for @kpiCommission.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي العمولات'**
  String get kpiCommission;

  /// No description provided for @kpiPendingApplications.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا طلبات انضمام معلّقة} =1{طلب انضمام واحد بانتظار المراجعة} =2{طلبا انضمام بانتظار المراجعة} few{{count} طلبات انضمام بانتظار المراجعة} other{{count} طلب انضمام بانتظار المراجعة}}'**
  String kpiPendingApplications(int count);

  /// No description provided for @kpiApprovedTechnicians.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا فنيين معتمدين} =1{فني معتمد واحد} =2{فنيان معتمدان} few{{count} فنيين معتمدين} other{{count} فني معتمد}}'**
  String kpiApprovedTechnicians(int count);

  /// No description provided for @adminRequestsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلبات'**
  String get adminRequestsTitle;

  /// No description provided for @adminFilterAttention.
  ///
  /// In ar, this message translates to:
  /// **'بحاجة لمتابعة'**
  String get adminFilterAttention;

  /// No description provided for @adminFilterActive.
  ///
  /// In ar, this message translates to:
  /// **'قيد التنفيذ'**
  String get adminFilterActive;

  /// No description provided for @adminFilterDone.
  ///
  /// In ar, this message translates to:
  /// **'منتهية'**
  String get adminFilterDone;

  /// No description provided for @adminFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get adminFilterAll;

  /// No description provided for @adminRequestsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا طلبات هنا.'**
  String get adminRequestsEmpty;

  /// No description provided for @errorOfferExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت مهلة هذا العرض.'**
  String get errorOfferExpired;

  /// No description provided for @errorOfferTaken.
  ///
  /// In ar, this message translates to:
  /// **'قبل فني آخر هذا الطلب بالفعل.'**
  String get errorOfferTaken;

  /// No description provided for @errorStateConflict.
  ///
  /// In ar, this message translates to:
  /// **'تغيّرت حالة الطلب. حدّث الصفحة وحاول مرة أخرى.'**
  String get errorStateConflict;

  /// No description provided for @onboardingSkip.
  ///
  /// In ar, this message translates to:
  /// **'تخطي'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In ar, this message translates to:
  /// **'صيانة بيتك في مكان واحد'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In ar, this message translates to:
  /// **'سباكة وكهرباء وتكييف ونجارة ونقاشة وأجهزة منزلية في أسوان.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In ar, this message translates to:
  /// **'فنيون تتم مراجعتهم'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In ar, this message translates to:
  /// **'كل فني يقدّم طلب انضمام، ولا يستقبل أي عمل إلا بعد موافقة المسؤول.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In ar, this message translates to:
  /// **'أنت تقرر قبل البدء'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In ar, this message translates to:
  /// **'راجع عرض السعر ووافق عليه، وتابع الحالة لحظة بلحظة، ثم قيّم الخدمة.'**
  String get onboarding3Body;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get phoneLabel;

  /// No description provided for @phoneInvalid.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم موبايل مصري صحيح، مثل 01012345678.'**
  String get phoneInvalid;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get passwordConfirmLabel;

  /// No description provided for @passwordRules.
  ///
  /// In ar, this message translates to:
  /// **'٨ أحرف على الأقل، منها حرف ورقم.'**
  String get passwordRules;

  /// No description provided for @passwordMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين.'**
  String get passwordMismatch;

  /// No description provided for @passwordRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل كلمة المرور.'**
  String get passwordRequired;

  /// No description provided for @showPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePassword;

  /// No description provided for @signInButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signInButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'جديد على صيانتك؟'**
  String get noAccountPrompt;

  /// No description provided for @createAccountLink.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ حساباً'**
  String get createAccountLink;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟'**
  String get haveAccountPrompt;

  /// No description provided for @signInLink.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول'**
  String get signInLink;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الحساب ثم أكمل بياناتك.'**
  String get registerSubtitle;

  /// No description provided for @accountTypeLabel.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get accountTypeLabel;

  /// No description provided for @accountTypeCustomerBlurb.
  ///
  /// In ar, this message translates to:
  /// **'اطلب خدمة وتابعها حتى تنتهي.'**
  String get accountTypeCustomerBlurb;

  /// No description provided for @accountTypeTechnicianBlurb.
  ///
  /// In ar, this message translates to:
  /// **'قدّم طلب انضمام واستقبل الأعمال بعد الموافقة.'**
  String get accountTypeTechnicianBlurb;

  /// No description provided for @registerButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get registerButton;

  /// No description provided for @localDataNote.
  ///
  /// In ar, this message translates to:
  /// **'يعمل التطبيق بدون إنترنت. الحسابات والبيانات محفوظة على هذا الجهاز فقط، وتتشاركها كل الحسابات المسجلة عليه.'**
  String get localDataNote;

  /// No description provided for @adminSetupPrompt.
  ///
  /// In ar, this message translates to:
  /// **'مالك الجهاز؟'**
  String get adminSetupPrompt;

  /// No description provided for @adminSetupLink.
  ///
  /// In ar, this message translates to:
  /// **'إعداد حساب المسؤول'**
  String get adminSetupLink;

  /// No description provided for @adminSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعداد حساب المسؤول'**
  String get adminSetupTitle;

  /// No description provided for @adminSetupBody.
  ///
  /// In ar, this message translates to:
  /// **'يمكن إنشاء أول حساب مسؤول مرة واحدة فقط على هذا الجهاز. بعدها لا يضيف مسؤولاً جديداً إلا مسؤول.'**
  String get adminSetupBody;

  /// No description provided for @adminSetupButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب المسؤول'**
  String get adminSetupButton;

  /// No description provided for @addAdminEntry.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مسؤول'**
  String get addAdminEntry;

  /// No description provided for @addAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مسؤول'**
  String get addAdminTitle;

  /// No description provided for @addAdminBody.
  ///
  /// In ar, this message translates to:
  /// **'سيتمكن من مراجعة الفنيين وإدارة الطلبات. أبلغه بكلمة المرور بطريقة آمنة.'**
  String get addAdminBody;

  /// No description provided for @addAdminButton.
  ///
  /// In ar, this message translates to:
  /// **'إضافة المسؤول'**
  String get addAdminButton;

  /// No description provided for @adminAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة المسؤول {name}.'**
  String adminAdded(String name);

  /// No description provided for @changePasswordEntry.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordEntry;

  /// No description provided for @changePasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة المرور'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الجديدة'**
  String get newPasswordLabel;

  /// No description provided for @passwordChanged.
  ///
  /// In ar, this message translates to:
  /// **'تم تغيير كلمة المرور.'**
  String get passwordChanged;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج؟'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In ar, this message translates to:
  /// **'ستحتاج رقمك وكلمة المرور للدخول مرة أخرى.'**
  String get signOutConfirmBody;

  /// No description provided for @aboutDataEntry.
  ///
  /// In ar, this message translates to:
  /// **'عن بياناتك'**
  String get aboutDataEntry;

  /// No description provided for @aboutDataBody.
  ///
  /// In ar, this message translates to:
  /// **'صيانتك نسخة تعمل محلياً بالكامل لأغراض مشروع دراسي. لا يوجد خادم: الحسابات والطلبات والرسائل والصور محفوظة في قاعدة بيانات على هذا الجهاز فقط، وكلمات المرور مخزنة كبصمة مشفرة لا يمكن استرجاعها. الإشعارات والمحادثات تصل فقط للحسابات المسجلة على نفس الجهاز، والدفع نقدي يُسجَّل يدوياً.'**
  String get aboutDataBody;

  /// No description provided for @gotIt.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get gotIt;

  /// No description provided for @tabApplication.
  ///
  /// In ar, this message translates to:
  /// **'طلب الانضمام'**
  String get tabApplication;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل أو كلمة المرور غير صحيحة.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorPhoneTaken.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرقم له حساب بالفعل. سجّل الدخول بدلاً من ذلك.'**
  String get errorPhoneTaken;

  /// No description provided for @errorTooManyAttempts.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة. حاول مرة أخرى بعد {minutes} دقيقة.'**
  String errorTooManyAttempts(int minutes);

  /// No description provided for @errorAdminExists.
  ///
  /// In ar, this message translates to:
  /// **'يوجد حساب مسؤول بالفعل على هذا الجهاز.'**
  String get errorAdminExists;

  /// No description provided for @errorAccountDisabled.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب موقوف.'**
  String get errorAccountDisabled;

  /// No description provided for @errorWrongPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور الحالية غير صحيحة.'**
  String get errorWrongPassword;

  /// No description provided for @errorTechnicianNotApproved.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يوافق المسؤول على طلب انضمامك أولاً.'**
  String get errorTechnicianNotApproved;
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
