import 'dart:typed_data';

import 'package:sianetak_customer/core/device/image_picker_service.dart';
import 'package:sianetak_customer/core/device/location_service.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/admin/data/admin_repository.dart';
import 'package:sianetak_customer/features/auth/data/auth_repository.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/catalog/data/catalog_repository.dart';
import 'package:sianetak_customer/features/catalog/domain/catalog_models.dart';
import 'package:sianetak_customer/features/media/data/media_repository.dart';
import 'package:sianetak_customer/features/media/domain/media_models.dart';
import 'package:sianetak_customer/features/requests/data/requests_repository.dart';
import 'package:sianetak_customer/features/requests/domain/request_models.dart';
import 'package:sianetak_customer/features/technician/data/technician_repository.dart';
import 'package:sianetak_customer/features/technician/domain/technician_models.dart';

LocalizedText text(String ar, String en) => LocalizedText(ar: ar, en: en);

ServiceCategory category({
  String slug = 'plumbing',
  String ar = 'سباكة',
  String en = 'Plumbing',
  int serviceCount = 2,
  bool isSample = true,
}) => ServiceCategory(
  id: 'cat-$slug',
  slug: slug,
  name: text(ar, en),
  description: text('وصف $ar', '$en description'),
  iconKey: slug,
  serviceCount: serviceCount,
  isSample: isSample,
);

ServiceSummary service({
  String slug = 'plumbing-leak-repair',
  String ar = 'إصلاح تسريب',
  String en = 'Leak repair',
  PricingGuidance? pricing,
  bool isSample = true,
}) => ServiceSummary(
  id: 'svc-$slug',
  slug: slug,
  name: text(ar, en),
  pricing: pricing ?? const PricingGuidance.inspectionRequired(),
  isSample: isSample,
);

/// In-memory catalog that can be told to fail or stall.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    List<ServiceCategory>? categories,
    List<ServiceSummary>? services,
    this.error,
  }) : categories = categories ?? [category()],
       services = services ?? [service()];

  List<ServiceCategory> categories;
  List<ServiceSummary> services;
  Object? error;
  int listCalls = 0;

  Future<T> _answer<T>(T value) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<List<ServiceCategory>> listCategories() {
    listCalls++;
    return _answer(categories);
  }

  @override
  Future<CategoryDetail> getCategory(String slug) =>
      _answer(CategoryDetail(category: categories.first, services: services));

  @override
  Future<ServiceDetail> getService(String slug) => _answer(
    ServiceDetail(
      summary: services.firstWhere(
        (s) => s.slug == slug,
        orElse: () => services.first,
      ),
      description: text('تفاصيل الخدمة', 'Service details'),
      categorySlug: categories.first.slug,
      categoryName: categories.first.name,
    ),
  );
}

/// Scriptable auth backend: records calls and returns queued answers.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.codeLength = 6, this.resendAfterSeconds = 60});

  final int codeLength;
  final int resendAfterSeconds;

  /// The code the fake server accepts.
  String validCode = '123456';
  Object? requestError;
  Object? verifyError;
  Object? refreshError = const ApiException(
    code: 'REFRESH_TOKEN_INVALID',
    statusCode: 401,
  );
  String? devCode;
  int requestCount = 0;
  int verifyCount = 0;
  int logoutCount = 0;
  String? lastName;
  AppUser user = const AppUser(
    id: 'u1',
    phone: '+201012345678',
    name: null,
    role: UserRole.customer,
  );

  @override
  Future<OtpChallenge> requestOtp(String phoneE164) async {
    requestCount++;
    if (requestError != null) throw requestError!;
    return OtpChallenge(
      challengeId: 'challenge-$requestCount',
      phone: phoneE164,
      codeLength: codeLength,
      resendAfterSeconds: resendAfterSeconds,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      devCode: devCode,
    );
  }

  @override
  Future<AuthSession> verifyOtp(OtpChallenge challenge, String code) async {
    verifyCount++;
    if (verifyError != null) throw verifyError!;
    if (code != validCode) {
      throw const ApiException(
        code: 'OTP_INVALID',
        statusCode: 400,
        details: {'attemptsRemaining': 4},
      );
    }
    return AuthSession(
      accessToken: 'access-$verifyCount',
      refreshToken: 'refresh-$verifyCount',
      user: user,
    );
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    if (refreshError != null) throw refreshError!;
    return AuthSession(
      accessToken: 'access-refreshed',
      refreshToken: 'refresh-rotated',
      user: user,
    );
  }

  @override
  Future<void> logout(String refreshToken) async => logoutCount++;

  @override
  Future<AppUser> fetchMe() async => user;

  @override
  Future<AppUser> updateName(String name) async {
    lastName = name;
    user = AppUser(id: user.id, phone: user.phone, name: name, role: user.role);
    return user;
  }
}

// ---------------------------------------------------------------------------
// Sprint 2: requests, media, technician onboarding and admin review.

ServiceArea area({
  String slug = 'aswan-city-centre',
  String ar = 'وسط المدينة',
  String en = 'City centre',
}) => ServiceArea(
  id: 'area-$slug',
  slug: slug,
  name: text(ar, en),
  isSample: true,
);

/// Slots start tomorrow so they never fall in the past while a test runs.
List<TimeSlot> sampleSlots() {
  final now = DateTime.now();
  final day = DateTime(now.year, now.month, now.day + 1);
  return [
    TimeSlot(
      from: day.add(const Duration(hours: 9)),
      to: day.add(const Duration(hours: 12)),
    ),
    TimeSlot(
      from: day.add(const Duration(hours: 12)),
      to: day.add(const Duration(hours: 15)),
    ),
  ];
}

RequestOptions requestOptions({
  List<ServiceArea>? areas,
  List<TimeSlot>? slots,
  bool uploadsAvailable = true,
  int maxPhotos = 3,
  int maxPhotoBytes = 1000,
  Money? inspectionFee,
}) => RequestOptions(
  descriptionMinLength: 10,
  descriptionMaxLength: 1000,
  maxPhotos: maxPhotos,
  maxPhotoBytes: maxPhotoBytes,
  uploadsAvailable: uploadsAvailable,
  asapAvailable: true,
  slots: slots ?? sampleSlots(),
  inspectionFee: inspectionFee,
  areas: areas ?? [area(), area(slug: 'kima', ar: 'كيما', en: 'Kima')],
);

/// A real (1×1 PNG) image unless [size] asks for blank bytes of that length.
PickedImage pickedImage([int? size, String name = 'photo.png']) => PickedImage(
  bytes: size == null ? transparentPng : Uint8List(size),
  name: name,
);

/// Records submissions (with their idempotency keys) and builds plausible responses.
class FakeRequestsRepository implements RequestsRepository {
  FakeRequestsRepository({
    RequestOptions? options,
    List<SavedAddress>? addresses,
  }) : currentOptions = options ?? requestOptions(),
       addresses = addresses ?? [];

  RequestOptions currentOptions;
  List<SavedAddress> addresses;
  final List<RequestDetail> created = [];
  final List<(RequestSubmission, String)> submissions = [];
  final Map<String, RequestDetail> _byKey = {};

  /// Errors thrown by the next submit calls, in order.
  final List<Object> submitErrors = [];
  Object? listError;
  int optionsCalls = 0;
  int listCalls = 0;

  @override
  Future<RequestOptions> options() async {
    optionsCalls++;
    return currentOptions;
  }

  @override
  Future<List<SavedAddress>> savedAddresses() async => addresses;

  @override
  Future<void> deleteAddress(String id) async =>
      addresses.removeWhere((a) => a.id == id);

  @override
  Future<RequestDetail> submit(
    RequestSubmission submission, {
    required String idempotencyKey,
  }) async {
    submissions.add((submission, idempotencyKey));
    if (submitErrors.isNotEmpty) throw submitErrors.removeAt(0);
    // Same key, same request: the server replays the original.
    final replay = _byKey[idempotencyKey];
    if (replay != null) return replay;
    final areaId =
        submission.address?.areaId ??
        addresses.firstWhere((a) => a.id == submission.addressId).area.id;
    final chosenArea = currentOptions.areas.firstWhere(
      (a) => a.id == areaId,
      orElse: () => addresses.first.area,
    );
    final n = created.length + 1;
    final detail = requestDetail(
      id: 'req-$n',
      reference: 'SN-261024-0000$n',
      description: submission.description,
      photoIds: submission.photoIds,
      area: chosenArea,
      details: submission.address?.details ?? 'saved',
      schedule: submission.schedule,
    );
    created.add(detail);
    _byKey[idempotencyKey] = detail;
    return detail;
  }

  @override
  Future<RequestPage> list({String? cursor}) async {
    listCalls++;
    if (listError != null) throw listError!;
    return RequestPage(items: [for (final d in created.reversed) d.summary]);
  }

  @override
  Future<RequestDetail> get(String id) async => created.firstWhere(
    (d) => d.summary.id == id,
    orElse: () =>
        throw const ApiException(code: 'REQUEST_NOT_FOUND', statusCode: 404),
  );
}

RequestDetail requestDetail({
  String id = 'req-1',
  String reference = 'SN-261024-00001',
  String description = 'الحنفية بتسرب مياه',
  List<String> photoIds = const [],
  ServiceArea? area,
  String details = 'شارع النيل، عمارة 5',
  RequestSchedule schedule = const RequestSchedule.asap(),
}) {
  final a = area ?? sampleArea;
  return RequestDetail(
    summary: RequestSummary(
      id: id,
      reference: reference,
      status: RequestStatus.submitted,
      service: RequestServiceRef(
        id: 'svc-plumbing-leak-repair',
        slug: 'plumbing-leak-repair',
        name: text('إصلاح تسريب', 'Leak repair'),
        categoryName: text('سباكة', 'Plumbing'),
      ),
      area: a,
      schedule: schedule,
      photoCount: photoIds.length,
      submittedAt: DateTime.now(),
    ),
    description: description,
    photoIds: photoIds,
    areaName: a.name,
    addressDetails: details,
    pricing: const PricingGuidance.inspectionRequired(),
    timeline: [
      RequestTimelineEntry(status: RequestStatus.submitted, at: DateTime.now()),
    ],
  );
}

final sampleArea = area();

/// Uploads succeed unless told to fail; content fetches return a tiny valid PNG.
class FakeMediaRepository implements MediaRepository {
  int _next = 0;
  final List<MediaPurpose> uploads = [];
  final List<String> removed = [];

  /// Errors thrown by the next uploads, in order.
  final List<Object> uploadErrors = [];

  @override
  Future<UploadedMedia> upload(MediaPurpose purpose, PickedImage file) async {
    uploads.add(purpose);
    if (uploadErrors.isNotEmpty) throw uploadErrors.removeAt(0);
    return UploadedMedia(
      id: 'media-${++_next}',
      contentType: 'image/jpeg',
      byteSize: file.bytes.length,
    );
  }

  @override
  Future<void> remove(String id) async => removed.add(id);

  @override
  Future<Uint8List> fetch(String id) async => transparentPng;
}

final transparentPng = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class FakeImagePicker implements ImagePickerService {
  /// What the next pick returns; an exception is thrown.
  Object? next = pickedImage();
  int picks = 0;

  @override
  Future<PickedImage?> pick(ImageOrigin origin) async {
    picks++;
    final value = next;
    if (value is Exception) throw value;
    return value as PickedImage?;
  }
}

class FakeLocationService implements LocationService {
  LocationResult result = const LocationResult.success(
    GeoPoint(24.0889, 32.8998),
  );
  int calls = 0;

  @override
  Future<LocationResult> current() async {
    calls++;
    return result;
  }
}

TechnicianApplication technicianApplication({
  String id = 'app-1',
  VerificationStatus status = VerificationStatus.pendingReview,
  String fullName = 'محمود علي',
  String? decisionReason,
  bool canResubmit = false,
  List<ApplicationDocument> documents = const [],
}) => TechnicianApplication(
  id: id,
  status: status,
  fullName: fullName,
  yearsOfExperience: 5,
  specialties: [
    SpecialtyRef(
      id: 'cat-plumbing',
      slug: 'plumbing',
      name: text('سباكة', 'Plumbing'),
    ),
  ],
  serviceAreas: [sampleArea],
  documents: documents,
  submittedAt: DateTime.now(),
  decisionReason: decisionReason,
  canResubmit: canResubmit,
  eligibleForWork: status == VerificationStatus.approved,
);

class FakeTechnicianRepository implements TechnicianRepository {
  FakeTechnicianRepository({this.application, this.minDocuments = 0});

  TechnicianApplication? application;
  int minDocuments;
  final List<ApplicationSubmission> submissions = [];
  Object? submitError;

  @override
  Future<OwnApplicationState> getOwn() async => OwnApplicationState(
    application: application,
    requirements: ApplicationRequirements(
      minDocuments: minDocuments,
      maxDocuments: 5,
      uploadsAvailable: true,
    ),
  );

  @override
  Future<TechnicianApplication> submit(ApplicationSubmission submission) async {
    submissions.add(submission);
    if (submitError != null) throw submitError!;
    return application = technicianApplication(fullName: submission.fullName);
  }

  @override
  Future<List<ServiceArea>> serviceAreas() async => [
    sampleArea,
    area(slug: 'kima', ar: 'كيما', en: 'Kima'),
  ];
}

class FakeAdminRepository implements AdminRepository {
  FakeAdminRepository([List<ReviewApplication>? applications])
    : applications = applications ?? [];

  final List<ReviewApplication> applications;
  final List<(String, ReviewAction, String?)> decisions = [];
  Object? decideError;

  @override
  Future<List<ApplicationSummary>> listApplications(
    VerificationStatus status,
  ) async => [
    for (final r in applications)
      if (r.application.status == status)
        ApplicationSummary(
          id: r.application.id,
          status: r.application.status,
          fullName: r.application.fullName,
          specialtyCount: r.application.specialties.length,
          areaCount: r.application.serviceAreas.length,
          documentCount: r.application.documents.length,
          submittedAt: r.application.submittedAt,
        ),
  ];

  @override
  Future<ReviewApplication> getApplication(String id) async =>
      applications.firstWhere((r) => r.application.id == id);

  @override
  Future<ReviewApplication> decide(
    String id,
    ReviewAction action, {
    String? reason,
  }) async {
    decisions.add((id, action, reason));
    if (decideError != null) throw decideError!;
    final i = applications.indexWhere((r) => r.application.id == id);
    final current = applications[i];
    final next = switch (action) {
      ReviewAction.approve => VerificationStatus.approved,
      ReviewAction.reject => VerificationStatus.rejected,
      ReviewAction.suspend => VerificationStatus.suspended,
    };
    final updated = ReviewApplication(
      application: technicianApplication(
        id: id,
        status: next,
        fullName: current.application.fullName,
        decisionReason: action == ReviewAction.approve ? null : reason,
        documents: current.application.documents,
      ),
      applicantPhone: current.applicantPhone,
      history: [
        ...current.history,
        ReviewHistoryEntry(
          action: 'technician_application.${next.name}',
          at: DateTime.now(),
          reason: reason,
        ),
      ],
    );
    applications[i] = updated;
    return updated;
  }
}

ReviewApplication reviewApplication({
  String id = 'app-1',
  VerificationStatus status = VerificationStatus.pendingReview,
  String fullName = 'محمود علي',
  List<ApplicationDocument> documents = const [
    ApplicationDocument(
      id: 'doc-1',
      kind: DocumentKind.identity,
      contentType: 'image/jpeg',
      byteSize: 100,
    ),
    ApplicationDocument(
      id: 'doc-2',
      kind: DocumentKind.qualification,
      contentType: 'application/pdf',
      byteSize: 200,
    ),
  ],
}) => ReviewApplication(
  application: technicianApplication(
    id: id,
    status: status,
    fullName: fullName,
    documents: documents,
  ),
  applicantPhone: '+201098765432',
  history: [
    ReviewHistoryEntry(
      action: 'technician_application.submitted',
      at: DateTime.now(),
    ),
  ],
);
