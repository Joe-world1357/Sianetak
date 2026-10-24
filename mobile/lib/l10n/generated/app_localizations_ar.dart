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
  String get signInToRequest => 'سجّل الدخول لطلب الخدمة';

  @override
  String get signInTitle => 'اختر حساب التجربة';

  @override
  String get signInSubtitle =>
      'نسخة عرض تعمل بالكامل على جهازك. جرّب التطبيق بأي دور.';

  @override
  String get errorSessionExpired => 'انتهت جلستك. سجّل الدخول مرة أخرى.';

  @override
  String get profileTitle => 'حسابي';

  @override
  String get profileNameLabel => 'الاسم';

  @override
  String get profileNameHint => 'اكتب اسمك';

  @override
  String get profileNameInvalid => 'أدخل اسمًا من حرفين على الأقل.';

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

  @override
  String get nextButton => 'التالي';

  @override
  String get backButton => 'السابق';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get editButton => 'تعديل';

  @override
  String stepOf(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get requestFlowTitle => 'طلب خدمة';

  @override
  String get stepDescribeTitle => 'صف المشكلة';

  @override
  String get stepLocationTitle => 'عنوان الخدمة';

  @override
  String get stepScheduleTitle => 'الموعد';

  @override
  String get stepReviewTitle => 'مراجعة الطلب';

  @override
  String get descriptionLabel => 'وصف المشكلة';

  @override
  String get descriptionHint => 'مثال: تسريب مياه تحت حوض المطبخ منذ يومين';

  @override
  String descriptionTooShort(int min) {
    return 'اكتب وصفًا من $min أحرف على الأقل.';
  }

  @override
  String descriptionTooLong(int max) {
    return 'الوصف أطول من $max حرف.';
  }

  @override
  String get photosTitle => 'صور (اختياري)';

  @override
  String photosHelp(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'أضف حتى $max صورة توضح المشكلة.',
      few: 'أضف حتى $max صور توضح المشكلة.',
      two: 'أضف حتى صورتين توضحان المشكلة.',
      one: 'أضف صورة واحدة توضح المشكلة.',
    );
    return '$_temp0 تُحذف بيانات الموقع من الصور تلقائيًا.';
  }

  @override
  String get addPhotoCamera => 'التقاط صورة';

  @override
  String get addPhotoGallery => 'من المعرض';

  @override
  String get photoUploading => 'جارٍ رفع الصورة';

  @override
  String get photoFailed => 'تعذّر رفع الصورة';

  @override
  String get photoRetry => 'إعادة رفع الصورة';

  @override
  String get photoRemove => 'حذف الصورة';

  @override
  String photoNumber(int number) {
    return 'صورة $number';
  }

  @override
  String get photosUploadingWait => 'انتظر حتى يكتمل رفع الصور.';

  @override
  String get photosFailedFix => 'أعد رفع الصور التي فشلت أو احذفها.';

  @override
  String photoLimitReached(int max) {
    String _temp0 = intl.Intl.pluralLogic(
      max,
      locale: localeName,
      other: 'يمكنك إضافة $max صورة كحد أقصى.',
      few: 'يمكنك إضافة $max صور كحد أقصى.',
      two: 'يمكنك إضافة صورتين كحد أقصى.',
      one: 'يمكنك إضافة صورة واحدة فقط.',
    );
    return '$_temp0';
  }

  @override
  String get photoTooLarge => 'الصورة كبيرة جدًا. اختر صورة أصغر.';

  @override
  String get photoUploadsUnavailable =>
      'رفع الصور غير متاح حاليًا. يمكنك إرسال الطلب بدون صور.';

  @override
  String get photoPermissionDenied =>
      'لم يُسمح بالوصول إلى الكاميرا أو الصور. يمكنك السماح بذلك من إعدادات الجهاز، أو المتابعة بدون صور.';

  @override
  String get photoPickFailed => 'تعذّر فتح الصورة. حاول مرة أخرى.';

  @override
  String get savedAddressesTitle => 'عناويني المحفوظة';

  @override
  String get newAddressOption => 'عنوان جديد';

  @override
  String get areaLabel => 'المنطقة';

  @override
  String get areaRequired => 'اختر المنطقة.';

  @override
  String get addressDetailsLabel => 'العنوان بالتفصيل';

  @override
  String get addressDetailsHint => 'الشارع، رقم العمارة، الدور، الشقة';

  @override
  String get addressDetailsTooShort => 'اكتب العنوان بتفصيل أكثر.';

  @override
  String get landmarkLabel => 'علامة مميزة (اختياري)';

  @override
  String get addressLabelLabel => 'اسم العنوان (اختياري)';

  @override
  String get addressLabelHint => 'مثال: البيت، العمل';

  @override
  String get saveAddressLabel => 'احفظ هذا العنوان للمرات القادمة';

  @override
  String get useCurrentLocation => 'استخدم موقعي الحالي';

  @override
  String get locating => 'جارٍ تحديد موقعك…';

  @override
  String get locationCaptured => 'تمت إضافة موقعك الحالي إلى العنوان.';

  @override
  String get locationRemove => 'إزالة الموقع';

  @override
  String get locationOptionalNote =>
      'الموقع اختياري ويساعد في الوصول إليك. لا يُستخدم إلا لطلباتك.';

  @override
  String get locationDenied =>
      'لم يُسمح بالوصول إلى الموقع. اكتب العنوان يدويًا.';

  @override
  String get locationDeniedForever =>
      'الوصول إلى الموقع مرفوض. يمكنك السماح به من إعدادات الجهاز، أو كتابة العنوان يدويًا.';

  @override
  String get locationServiceOff =>
      'خدمة الموقع مغلقة في جهازك. شغّلها أو اكتب العنوان يدويًا.';

  @override
  String get locationUnavailable => 'تعذّر تحديد موقعك. اكتب العنوان يدويًا.';

  @override
  String get addressMissing => 'اختر عنوانًا.';

  @override
  String get noAreasConfigured => 'لا توجد مناطق خدمة متاحة حاليًا.';

  @override
  String get scheduleAsap => 'في أقرب وقت';

  @override
  String get scheduleAsapHint => 'بدون موعد محدد.';

  @override
  String get scheduleChooseSlot => 'أو اختر موعدًا';

  @override
  String get scheduleNoSlots => 'لا توجد مواعيد متاحة حاليًا.';

  @override
  String get scheduleMissing => 'اختر موعدًا أو «في أقرب وقت».';

  @override
  String slotRange(String day, String from, String to) {
    return '$day، $from – $to';
  }

  @override
  String get reviewServiceLabel => 'الخدمة';

  @override
  String get reviewDescriptionLabel => 'المشكلة';

  @override
  String get reviewPhotosLabel => 'الصور';

  @override
  String get reviewNoPhotos => 'بدون صور';

  @override
  String get reviewLocationLabel => 'العنوان';

  @override
  String get reviewScheduleLabel => 'الموعد';

  @override
  String get reviewPricingLabel => 'التسعير والرسوم';

  @override
  String feeInspection(String amount) {
    return 'رسوم المعاينة: $amount';
  }

  @override
  String get feeNoneAtSubmission =>
      'لا تُدفع أي رسوم عند إرسال الطلب. أي سعر أو رسوم ستُعرض عليك لتوافق عليها قبل بدء العمل.';

  @override
  String get reviewNextSteps => 'بعد الإرسال سنراجع طلبك. لم يُعيَّن فني بعد.';

  @override
  String get submitRequestButton => 'إرسال الطلب';

  @override
  String get submittingLabel => 'جارٍ الإرسال…';

  @override
  String get submitFailedRetry =>
      'لم يُرسل الطلب. تحقق من الاتصال واضغط «إرسال الطلب» مرة أخرى، ولن يتكرر طلبك.';

  @override
  String get requestSubmittedTitle => 'تم إرسال طلبك';

  @override
  String get requestReferenceLabel => 'رقم الطلب';

  @override
  String get requestSubmittedBody =>
      'حالة الطلب: «تم الاستلام». يمكنك متابعته من «طلباتي».';

  @override
  String get viewRequestButton => 'عرض الطلب';

  @override
  String get backToHomeButton => 'العودة للرئيسية';

  @override
  String get statusSubmitted => 'بانتظار فني';

  @override
  String get statusUnknown => 'غير معروف';

  @override
  String get myRequestsTitle => 'طلباتي';

  @override
  String get myRequestsEmpty => 'لم ترسل أي طلب بعد. اختر خدمة لتبدأ.';

  @override
  String get loadMoreButton => 'عرض المزيد';

  @override
  String submittedOn(String date) {
    return 'أُرسل في $date';
  }

  @override
  String get requestDetailTitle => 'تفاصيل الطلب';

  @override
  String get timelineTitle => 'سجل الطلب';

  @override
  String get photoLoadFailed => 'تعذّر تحميل الصورة';

  @override
  String get requestsCustomerOnly => 'طلب الخدمات متاح لحسابات العملاء فقط.';

  @override
  String get errorServiceNotAvailable => 'هذه الخدمة غير متاحة حاليًا.';

  @override
  String get errorAreaNotAvailable => 'هذه المنطقة غير مخدومة حاليًا.';

  @override
  String get errorLocationOutOfArea => 'الموقع خارج نطاق الخدمة.';

  @override
  String get errorInvalidSchedule =>
      'هذا الموعد لم يعد متاحًا. اختر موعدًا آخر.';

  @override
  String get errorTooManyOpenRequests =>
      'لديك طلبات مفتوحة كثيرة. انتظر حتى تُنجز قبل إرسال طلب جديد.';

  @override
  String get errorMediaInvalid =>
      'أحد الملفات لم يعد صالحًا. احذفه وأعد إضافته.';

  @override
  String get errorFileTooLarge => 'الملف كبير جدًا.';

  @override
  String get errorUnsupportedFile =>
      'نوع الملف غير مدعوم. استخدم صورة JPG أو PNG.';

  @override
  String get errorMediaUnavailable => 'رفع الملفات غير متاح حاليًا.';

  @override
  String get errorMediaPendingLimit =>
      'لديك ملفات مرفوعة كثيرة لم تُستخدم بعد. احذف بعضها أولًا.';

  @override
  String get errorAddressNotFound =>
      'هذا العنوان لم يعد موجودًا. اختر عنوانًا آخر.';

  @override
  String get errorAddressLimit => 'وصلت إلى الحد الأقصى من العناوين المحفوظة.';

  @override
  String get errorValidation =>
      'بعض البيانات غير صحيحة. راجعها وحاول مرة أخرى.';

  @override
  String get errorForbidden => 'ليس لديك صلاحية لهذا الإجراء.';

  @override
  String get errorApplicationAlreadySubmitted =>
      'طلب الانضمام قيد المراجعة بالفعل.';

  @override
  String get errorApplicationStateConflict => 'تغيّرت حالة الطلب. حدّث الصفحة.';

  @override
  String get errorCategoryNotAvailable => 'أحد التخصصات لم يعد متاحًا.';

  @override
  String errorDocumentsRequired(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'أرفق $min مستندًا على الأقل.',
      few: 'أرفق $min مستندات على الأقل.',
      two: 'أرفق مستندين على الأقل.',
      one: 'أرفق مستندًا واحدًا على الأقل.',
    );
    return '$_temp0';
  }

  @override
  String get errorCannotReviewOwn => 'لا يمكنك مراجعة طلبك الشخصي.';

  @override
  String get technicianEntryApply => 'انضم كفني';

  @override
  String get technicianEntryStatus => 'طلب الانضمام كفني';

  @override
  String get technicianApplyTitle => 'الانضمام كفني';

  @override
  String get technicianApplyIntro =>
      'أرسل بياناتك لتراجعها الإدارة. لن تتلقى أي طلبات عمل قبل اعتماد حسابك.';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameInvalid => 'أدخل اسمك الكامل بالحروف.';

  @override
  String get yearsLabel => 'سنوات الخبرة (اختياري)';

  @override
  String get yearsInvalid => 'أدخل رقمًا من 0 إلى 60.';

  @override
  String get bioLabel => 'نبذة عن خبرتك (اختياري)';

  @override
  String get specialtiesTitle => 'التخصصات';

  @override
  String get specialtiesRequired => 'اختر تخصصًا واحدًا على الأقل.';

  @override
  String get serviceAreasTitle => 'مناطق العمل';

  @override
  String get serviceAreasRequired => 'اختر منطقة واحدة على الأقل.';

  @override
  String get documentsTitle => 'مستندات التحقق';

  @override
  String get documentsOptionalHelp =>
      'المستندات المطلوبة لم تُحدَّد بعد. أرفق ما يثبت هويتك أو خبرتك إن وُجد.';

  @override
  String documentsMinHelp(int min) {
    String _temp0 = intl.Intl.pluralLogic(
      min,
      locale: localeName,
      other: 'أرفق $min مستندًا على الأقل.',
      few: 'أرفق $min مستندات على الأقل.',
      two: 'أرفق مستندين على الأقل.',
      one: 'أرفق مستندًا واحدًا على الأقل.',
    );
    return '$_temp0';
  }

  @override
  String get documentsPrivacy =>
      'المستندات خاصة، ولا يطّلع عليها إلا فريق المراجعة.';

  @override
  String get documentKindLabel => 'نوع المستند';

  @override
  String get documentKindIdentity => 'إثبات الهوية';

  @override
  String get documentKindQualification => 'شهادة أو خبرة';

  @override
  String get documentKindOther => 'أخرى';

  @override
  String documentNumber(int number) {
    return 'مستند $number';
  }

  @override
  String get documentRemove => 'حذف المستند';

  @override
  String get documentLimitReached => 'وصلت إلى الحد الأقصى من المستندات.';

  @override
  String get submitApplicationButton => 'إرسال طلب الانضمام';

  @override
  String get resubmitApplicationButton => 'تعديل وإعادة الإرسال';

  @override
  String get applicationSubmittedMessage => 'تم إرسال طلبك للمراجعة.';

  @override
  String get applicationStatusTitle => 'طلب الانضمام كفني';

  @override
  String get verificationPending => 'قيد المراجعة';

  @override
  String get verificationPendingBody =>
      'تراجع الإدارة بياناتك، وستظهر النتيجة هنا.';

  @override
  String get verificationApproved => 'معتمد';

  @override
  String get verificationApprovedBody =>
      'تم اعتماد حسابك كفني. استقبال طلبات العمل سيتاح في تحديث قادم.';

  @override
  String get verificationRejected => 'لم يُقبل';

  @override
  String get verificationRejectedBody => 'يمكنك تعديل بياناتك وإعادة الإرسال.';

  @override
  String get verificationRejectedFinal =>
      'لا يمكن إعادة الإرسال حاليًا. تواصل مع الدعم.';

  @override
  String get verificationSuspended => 'موقوف';

  @override
  String get verificationSuspendedBody =>
      'تم إيقاف حسابك كفني مؤقتًا. تواصل مع الدعم.';

  @override
  String get decisionReasonLabel => 'سبب القرار';

  @override
  String get adminApplicationsTitle => 'طلبات الفنيين';

  @override
  String get adminApplicationsEmpty => 'لا توجد طلبات بهذه الحالة.';

  @override
  String adminApplicationMeta(int specialties, int areas, int documents) {
    return 'التخصصات: $specialties · المناطق: $areas · المستندات: $documents';
  }

  @override
  String get adminApplicantPhone => 'رقم الموبايل';

  @override
  String yearsValue(int years) {
    return 'سنوات الخبرة: $years';
  }

  @override
  String get documentsNone => 'لا توجد مستندات';

  @override
  String get pdfDocumentLabel => 'ملف PDF (المعاينة غير متاحة في التطبيق)';

  @override
  String get adminHistoryTitle => 'سجل المراجعة';

  @override
  String get historySubmitted => 'أرسل الطلب';

  @override
  String get historyResubmitted => 'أعاد الإرسال';

  @override
  String get historyApproved => 'اعتماد';

  @override
  String get historyRejected => 'رفض';

  @override
  String get historySuspended => 'إيقاف';

  @override
  String get adminApproveButton => 'اعتماد';

  @override
  String get adminRejectButton => 'رفض';

  @override
  String get adminSuspendButton => 'إيقاف';

  @override
  String get adminReinstateButton => 'إعادة التفعيل';

  @override
  String get adminApproveTitle => 'اعتماد الفني؟';

  @override
  String get adminApproveBody => 'سيصبح الحساب حساب فني معتمد.';

  @override
  String get adminRejectTitle => 'رفض الطلب';

  @override
  String get adminSuspendTitle => 'إيقاف الفني';

  @override
  String get adminNoteLabel => 'ملاحظة داخلية (اختياري)';

  @override
  String get adminReasonLabel => 'السبب (يظهر لمقدم الطلب)';

  @override
  String get adminReasonRequired => 'اكتب سببًا من 3 أحرف على الأقل.';

  @override
  String get adminDecisionSaved => 'تم حفظ القرار.';

  @override
  String get statusUnmatched => 'بانتظار الإدارة';

  @override
  String get statusAssigned => 'تم تعيين فني';

  @override
  String get statusEnRoute => 'الفني في الطريق';

  @override
  String get statusArrived => 'وصل الفني';

  @override
  String get statusQuoted => 'بانتظار موافقة السعر';

  @override
  String get statusQuoteRejected => 'العرض مرفوض';

  @override
  String get statusInProgress => 'جارٍ التنفيذ';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get demoCustomerBlurb =>
      'اطلب خدمة، تابع الفني، وافق على السعر وقيّم.';

  @override
  String get demoTechnicianBlurb =>
      'استقبل العروض، حدّث حالة العمل وأرسل عرض السعر.';

  @override
  String get demoAdminBlurb =>
      'تابع الطلبات، عيّن الفنيين وراجع طلبات الانضمام.';

  @override
  String get demoOfflineNote =>
      'لا حاجة لإنترنت أو رمز تحقق. تُحفظ البيانات على هذا الجهاز ويمكن إعادة ضبطها من حسابي.';

  @override
  String homeGreeting(String name) {
    return 'أهلًا $name 👋';
  }

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabRequests => 'طلباتي';

  @override
  String get tabNotifications => 'الإشعارات';

  @override
  String get tabAccount => 'حسابي';

  @override
  String get tabOffers => 'العروض';

  @override
  String get tabJobs => 'أعمالي';

  @override
  String get tabDashboard => 'لوحة التحكم';

  @override
  String get tabTechnicians => 'الفنيون';

  @override
  String get languageSetting => 'اللغة';

  @override
  String get switchAccountButton => 'التبديل إلى حساب آخر';

  @override
  String get resetDemoButton => 'إعادة ضبط بيانات التجربة';

  @override
  String get resetDemoTitle => 'إعادة ضبط البيانات؟';

  @override
  String get resetDemoBody =>
      'ستُحذف كل الطلبات والرسائل والصور على هذا الجهاز وتعود بيانات التجربة الأصلية.';

  @override
  String get technicianCardTitle => 'الفني';

  @override
  String get customerCardTitle => 'العميل';

  @override
  String get ratingNone => 'لا تقييمات بعد';

  @override
  String ratingSummary(String avg, int count) {
    return '$avg ($count)';
  }

  @override
  String ratingStars(int stars) {
    return '$stars من ٥ نجوم';
  }

  @override
  String get ratingTitle => 'تقييمك';

  @override
  String get etaEstimate => 'الوصول المتوقع خلال ٢٠–٣٠ دقيقة تقريبًا';

  @override
  String get chatOpenButton => 'محادثة الطلب';

  @override
  String get chatViewButton => 'عرض المحادثة';

  @override
  String get chatTitle => 'المحادثة';

  @override
  String get chatEmpty => 'لا رسائل بعد. اكتب أول رسالة.';

  @override
  String get chatHint => 'اكتب رسالة…';

  @override
  String get chatSend => 'إرسال';

  @override
  String get chatReadOnly => 'المحادثة للعرض فقط.';

  @override
  String get paymentTitle => 'الدفع';

  @override
  String get paymentCashCollected => 'تم التحصيل نقدًا';

  @override
  String get paymentCommission => 'عمولة المنصة';

  @override
  String get paymentRecordedAt => 'وقت التسجيل';

  @override
  String get cancelReasonTitle => 'سبب الإلغاء';

  @override
  String get addressHiddenUntilAccepted =>
      'يظهر العنوان بالتفصيل بعد قبول الطلب.';

  @override
  String get byOperations => 'بواسطة الإدارة';

  @override
  String get quoteTitle => 'عرض السعر';

  @override
  String get quotePending => 'بانتظار الموافقة';

  @override
  String get quoteApproved => 'تمت الموافقة';

  @override
  String get quoteRejected => 'مرفوض';

  @override
  String journeyStep(int step, int total) {
    return 'المرحلة $step من $total';
  }

  @override
  String get cancelRequestButton => 'إلغاء الطلب';

  @override
  String get cancelSheetTitle => 'لماذا تريد إلغاء الطلب؟';

  @override
  String get cancelReasonChangedMind => 'لم أعد بحاجة للخدمة';

  @override
  String get cancelReasonFixed => 'تم حل المشكلة';

  @override
  String get cancelReasonTooLong => 'الانتظار طويل';

  @override
  String get cancelReasonOther => 'سبب آخر';

  @override
  String get requestCancelledToast => 'تم إلغاء الطلب.';

  @override
  String get customerSearchingTitle => 'نبحث لك عن فني مناسب';

  @override
  String get customerSearchingBody =>
      'أرسلنا طلبك للفنيين المعتمدين في منطقتك. ستصلك رسالة فور قبول أحدهم.';

  @override
  String get customerUnmatchedTitle => 'لم يقبل أي فني بعد';

  @override
  String get customerUnmatchedBody =>
      'فريق التشغيل سيعيّن لك فنيًا يدويًا في أقرب وقت.';

  @override
  String get customerAssignedTitle => 'فنيك جاهز';

  @override
  String get customerAssignedBody =>
      'سيعاين الفني المشكلة ثم يرسل لك عرض سعر قبل بدء أي عمل.';

  @override
  String customerQuoteTitle(String amount) {
    return 'عرض سعر: $amount';
  }

  @override
  String get customerQuoteBody =>
      'لن يبدأ العمل إلا بعد موافقتك. الدفع نقدًا عند الانتهاء.';

  @override
  String get customerQuoteRejectedTitle => 'رفضت عرض السعر';

  @override
  String get customerQuoteRejectedBody =>
      'يمكن للفني إرسال عرض جديد، أو يمكنك إلغاء الطلب.';

  @override
  String get customerInProgressTitle => 'العمل جارٍ الآن';

  @override
  String get customerInProgressBody =>
      'سيؤكد الفني الانتهاء وتحصيل المبلغ المتفق عليه.';

  @override
  String get customerCompletedTitle => 'اكتملت الخدمة';

  @override
  String get customerCompletedBody => 'شاركنا رأيك في الفني لمساعدة الآخرين.';

  @override
  String get approveQuoteButton => 'الموافقة على السعر';

  @override
  String get rejectQuoteButton => 'رفض العرض';

  @override
  String get quoteApprovedToast => 'تمت الموافقة. أبلغنا الفني ليبدأ العمل.';

  @override
  String get rateButton => 'قيّم الخدمة';

  @override
  String get rateSheetTitle => 'كيف كانت الخدمة؟';

  @override
  String get rateCommentLabel => 'تعليق (اختياري)';

  @override
  String get rateSubmitButton => 'إرسال التقييم';

  @override
  String get ratingThanks => 'شكرًا لتقييمك!';

  @override
  String get offerForYouTitle => 'طلب جديد لك';

  @override
  String offerExpiresIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'ينتهي خلال $minutes دقيقة',
      few: 'ينتهي خلال $minutes دقائق',
      two: 'ينتهي خلال دقيقتين',
      one: 'ينتهي خلال دقيقة',
      zero: 'ينتهي العرض الآن',
    );
    return '$_temp0';
  }

  @override
  String get acceptOfferButton => 'قبول الطلب';

  @override
  String get declineOfferButton => 'اعتذار';

  @override
  String get offerAcceptedToast => 'تم قبول الطلب وأبلغنا العميل.';

  @override
  String get techAssignedTitle => 'الطلب لك';

  @override
  String get techAssignedBody => 'أبلغ العميل عندما تتحرك إليه.';

  @override
  String get onMyWayButton => 'أنا في الطريق';

  @override
  String get arrivedButton => 'وصلت';

  @override
  String get customerNotifiedToast => 'تم إبلاغ العميل.';

  @override
  String get techQuoteNeededTitle => 'عاين وأرسل عرض السعر';

  @override
  String get techQuoteRejectedTitle => 'رفض العميل العرض';

  @override
  String get techQuoteNeededBody =>
      'لا يبدأ العمل قبل موافقة العميل على السعر.';

  @override
  String get sendQuoteButton => 'إرسال عرض السعر';

  @override
  String get techAwaitingApprovalTitle => 'بانتظار موافقة العميل';

  @override
  String get techAwaitingApprovalBody =>
      'سنبلغك فور الموافقة على العرض أو رفضه.';

  @override
  String get techWorkingTitle => 'تمت الموافقة، ابدأ العمل';

  @override
  String techWorkingBody(String amount) {
    return 'عند الانتهاء حصّل $amount نقدًا وأكّد الإنجاز.';
  }

  @override
  String get completeJobButton => 'تم الانتهاء وتحصيل المبلغ';

  @override
  String get completeJobTitle => 'تأكيد الانتهاء';

  @override
  String completeJobBody(String amount) {
    return 'هل انتهى العمل وتم تحصيل $amount نقدًا من العميل؟';
  }

  @override
  String get jobCompletedToast => 'تم تسجيل الإنجاز والدفع.';

  @override
  String get quoteSheetTitle => 'عرض السعر';

  @override
  String get quoteSheetHint =>
      'أدخل السعر الإجمالي (مصنعية وقطع غيار) بعد المعاينة.';

  @override
  String get quoteAmountLabel => 'المبلغ';

  @override
  String get quoteAmountInvalid => 'أدخل مبلغًا صحيحًا.';

  @override
  String get quoteNoteLabel => 'تفاصيل العمل (اختياري)';

  @override
  String get currencyEgpShort => 'ج.م';

  @override
  String get quoteSentToast => 'تم إرسال العرض للعميل.';

  @override
  String get adminSearchingTitle => 'العروض مرسلة للفنيين';

  @override
  String get adminUnmatchedTitle => 'يحتاج تعيينًا يدويًا';

  @override
  String get adminAssignBody => 'يمكنك تعيين فني معتمد يغطي الخدمة والمنطقة.';

  @override
  String get assignTechnicianButton => 'تعيين فني';

  @override
  String get assignSheetTitle => 'اختر فنيًا';

  @override
  String get assignNoneEligible =>
      'لا يوجد فني معتمد يغطي هذه الخدمة والمنطقة.';

  @override
  String get assignedToast => 'تم تعيين الفني.';

  @override
  String get offersTitle => 'عروض العمل';

  @override
  String get offersIntro =>
      'طلبات تناسب تخصصك ومنطقتك. أول من يقبل يحصل على الطلب.';

  @override
  String get offersEmpty => 'لا عروض جديدة الآن. سنبلغك عند وصول طلب.';

  @override
  String get myJobsTitle => 'أعمالي';

  @override
  String get jobsActiveTab => 'الحالية';

  @override
  String get jobsHistoryTab => 'السابقة';

  @override
  String get jobsEmptyActive => 'لا أعمال حالية. اقبل عرضًا لتبدأ.';

  @override
  String get jobsEmptyHistory => 'لا أعمال منتهية بعد.';

  @override
  String get earningsTitle => 'صافي أرباحك';

  @override
  String get earningsNetHint => 'بعد خصم عمولة المنصة (١٠٪ — قيمة مقترحة)';

  @override
  String get earningsJobs => 'أعمال';

  @override
  String get earningsCollected => 'المحصّل';

  @override
  String get earningsCommission => 'العمولة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا إشعارات بعد.';

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String ntfNewOffer(String ref) {
    return 'طلب جديد يناسبك $ref';
  }

  @override
  String ntfAssignedByAdmin(String ref) {
    return 'عيّنتك الإدارة على الطلب $ref';
  }

  @override
  String ntfAssigned(String ref) {
    return 'تم تعيين فني لطلبك $ref';
  }

  @override
  String ntfEnRoute(String ref) {
    return 'الفني في الطريق إليك $ref';
  }

  @override
  String ntfArrived(String ref) {
    return 'وصل الفني $ref';
  }

  @override
  String ntfQuoted(String ref) {
    return 'وصلك عرض سعر للطلب $ref';
  }

  @override
  String ntfQuoteApproved(String ref) {
    return 'وافق العميل على عرضك $ref';
  }

  @override
  String ntfQuoteRejected(String ref) {
    return 'رفض العميل عرضك $ref';
  }

  @override
  String ntfCompleted(String ref) {
    return 'اكتملت الخدمة $ref. قيّم الفني';
  }

  @override
  String ntfRated(String ref) {
    return 'وصلك تقييم جديد $ref';
  }

  @override
  String ntfMessage(String ref) {
    return 'رسالة جديدة بخصوص $ref';
  }

  @override
  String ntfCancelled(String ref) {
    return 'تم إلغاء الطلب $ref';
  }

  @override
  String ntfUnmatched(String ref) {
    return 'الطلب $ref يحتاج تعيين فني';
  }

  @override
  String get ntfApplicationSubmitted => 'طلب انضمام فني جديد بانتظار المراجعة';

  @override
  String get ntfApplicationApproved => 'تمت الموافقة على طلب انضمامك كفني';

  @override
  String get ntfApplicationRejected => 'لم تتم الموافقة على طلب انضمامك';

  @override
  String get ntfApplicationSuspended => 'تم إيقاف حسابك كفني مؤقتًا';

  @override
  String get adminDashboardTitle => 'لوحة التشغيل';

  @override
  String get kpiNeedsAttention => 'بحاجة لمتابعة';

  @override
  String get kpiInProgress => 'قيد التنفيذ';

  @override
  String get kpiCompleted => 'مكتملة';

  @override
  String get kpiCommission => 'إجمالي العمولات';

  @override
  String kpiPendingApplications(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب انضمام بانتظار المراجعة',
      few: '$count طلبات انضمام بانتظار المراجعة',
      two: 'طلبا انضمام بانتظار المراجعة',
      one: 'طلب انضمام واحد بانتظار المراجعة',
      zero: 'لا طلبات انضمام معلّقة',
    );
    return '$_temp0';
  }

  @override
  String kpiApprovedTechnicians(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count فني معتمد',
      few: '$count فنيين معتمدين',
      two: 'فنيان معتمدان',
      one: 'فني معتمد واحد',
      zero: 'لا فنيين معتمدين',
    );
    return '$_temp0';
  }

  @override
  String get adminRequestsTitle => 'الطلبات';

  @override
  String get adminFilterAttention => 'بحاجة لمتابعة';

  @override
  String get adminFilterActive => 'قيد التنفيذ';

  @override
  String get adminFilterDone => 'منتهية';

  @override
  String get adminFilterAll => 'الكل';

  @override
  String get adminRequestsEmpty => 'لا طلبات هنا.';

  @override
  String get errorOfferExpired => 'انتهت مهلة هذا العرض.';

  @override
  String get errorOfferTaken => 'قبل فني آخر هذا الطلب بالفعل.';

  @override
  String get errorStateConflict =>
      'تغيّرت حالة الطلب. حدّث الصفحة وحاول مرة أخرى.';
}
