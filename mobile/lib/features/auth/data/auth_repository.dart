import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';

abstract class AuthRepository {
  Future<OtpChallenge> requestOtp(String phoneE164);
  Future<AuthSession> verifyOtp(OtpChallenge challenge, String code);
  Future<AuthSession> refresh(String refreshToken);
  Future<void> logout(String refreshToken);
  Future<AppUser> fetchMe();
  Future<AppUser> updateName(String name);
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<OtpChallenge> requestOtp(String phoneE164) async {
    final json = await _api.post(
      '/auth/otp/request',
      body: {'phone': phoneE164},
    );
    return OtpChallenge.fromJson(phoneE164, json);
  }

  @override
  Future<AuthSession> verifyOtp(OtpChallenge challenge, String code) async {
    final json = await _api.post(
      '/auth/otp/verify',
      body: {
        'challengeId': challenge.challengeId,
        'phone': challenge.phone,
        'code': code,
      },
    );
    return AuthSession.fromJson(json);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async =>
      AuthSession.fromJson(
        await _api.post('/auth/refresh', body: {'refreshToken': refreshToken}),
      );

  @override
  Future<void> logout(String refreshToken) =>
      _api.post('/auth/logout', body: {'refreshToken': refreshToken});

  @override
  Future<AppUser> fetchMe() async =>
      AppUser.fromJson(await _api.get('/me', authenticated: true));

  @override
  Future<AppUser> updateName(String name) async => AppUser.fromJson(
    await _api.patch('/me', body: {'name': name}, authenticated: true),
  );
}
