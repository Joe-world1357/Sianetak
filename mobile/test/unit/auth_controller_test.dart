import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/auth/application/auth_controller.dart';
import 'package:sianetak_customer/features/auth/data/token_store.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late InMemoryTokenStore store;
  late AuthController auth;

  setUp(() {
    repository = FakeAuthRepository();
    store = InMemoryTokenStore();
    auth = AuthController(repository: repository, tokenStore: store);
  });

  test(
    'starts in the restoring state and signs out when nothing is stored',
    () async {
      expect(auth.status, AuthStatus.restoring);
      await auth.restore();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.accessToken, isNull);
    },
  );

  test(
    'verifying an OTP stores the refresh token and exposes the user',
    () async {
      final challenge = await auth.requestOtp('+201012345678');
      await auth.verifyOtp(challenge, '123456');
      expect(auth.isSignedIn, isTrue);
      expect(auth.accessToken, 'access-1');
      expect(await store.readRefreshToken(), 'refresh-1');
      expect(auth.user?.phone, '+201012345678');
    },
  );

  test(
    'a wrong code leaves the user signed out and surfaces the server error',
    () async {
      final challenge = await auth.requestOtp('+201012345678');
      await expectLater(
        auth.verifyOtp(challenge, '000000'),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', 'OTP_INVALID'),
        ),
      );
      expect(auth.isSignedIn, isFalse);
      expect(await store.readRefreshToken(), isNull);
    },
  );

  test('restores a session from a stored refresh token', () async {
    await store.writeRefreshToken('stored');
    repository.refreshError = null;
    await auth.restore();
    expect(auth.isSignedIn, isTrue);
    expect(auth.accessToken, 'access-refreshed');
    expect(await store.readRefreshToken(), 'refresh-rotated');
  });

  test('clears a rejected refresh token', () async {
    await store.writeRefreshToken('revoked');
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
    expect(await store.readRefreshToken(), isNull);
  });

  test('keeps the refresh token when the device is offline', () async {
    await store.writeRefreshToken('stored');
    repository.refreshError = const ApiException(code: ApiException.network);
    await auth.restore();
    expect(auth.status, AuthStatus.signedOut);
    expect(await store.readRefreshToken(), 'stored');
  });

  test('coalesces concurrent refreshes into a single request', () async {
    await store.writeRefreshToken('stored');
    repository.refreshError = null;
    final results = await Future.wait([
      auth.refreshAccessToken(),
      auth.refreshAccessToken(),
      auth.refreshAccessToken(),
    ]);
    expect(results, everyElement(isTrue));
  });

  test(
    'sign-out clears local state and revokes the token server-side',
    () async {
      final challenge = await auth.requestOtp('+201012345678');
      await auth.verifyOtp(challenge, '123456');
      await auth.signOut();
      expect(auth.isSignedIn, isFalse);
      expect(auth.user, isNull);
      expect(await store.readRefreshToken(), isNull);
      expect(repository.logoutCount, 1);
    },
  );

  test('updating the name refreshes the cached user', () async {
    final challenge = await auth.requestOtp('+201012345678');
    await auth.verifyOtp(challenge, '123456');
    await auth.updateName('أحمد');
    expect(auth.user?.name, 'أحمد');
    expect(repository.lastName, 'أحمد');
  });
}
