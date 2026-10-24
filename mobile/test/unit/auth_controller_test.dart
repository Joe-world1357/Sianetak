import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/auth/application/auth_controller.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthController auth;

  setUp(() {
    repository = FakeAuthRepository();
    auth = AuthController(repository: repository);
  });

  test(
    'starts restoring and becomes signed out with no saved account',
    () async {
      expect(auth.status, AuthStatus.restoring);
      await auth.restore();
      expect(auth.status, AuthStatus.signedOut);
      expect(auth.user, isNull);
    },
  );

  test('restores the account saved from the last launch', () async {
    repository.signedIn = repository.user;
    await auth.restore();
    expect(auth.isSignedIn, isTrue);
    expect(auth.user!.id, 'u1');
  });

  test('signing in as a demo account notifies listeners', () async {
    var notified = 0;
    auth.addListener(() => notified++);
    await auth.signInAs('u1');
    expect(auth.isSignedIn, isTrue);
    expect(auth.user!.role, UserRole.customer);
    expect(notified, 1);
  });

  test('signing out clears the user locally and in storage', () async {
    await auth.signInAs('u1');
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    expect(repository.signOutCount, 1);
    expect(repository.signedIn, isNull);
  });

  test('updating the name refreshes the cached user', () async {
    await auth.signInAs('u1');
    await auth.updateName('منى');
    expect(auth.user!.name, 'منى');
    expect(repository.lastName, 'منى');
  });
}
