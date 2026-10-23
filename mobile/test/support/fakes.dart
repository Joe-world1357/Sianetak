import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/auth/data/auth_repository.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/catalog/data/catalog_repository.dart';
import 'package:sianetak_customer/features/catalog/domain/catalog_models.dart';

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
