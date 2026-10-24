import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
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

  test('remembers whether the welcome screens were seen', () async {
    repository.onboardingDone = false;
    await auth.restore();
    expect(auth.onboardingSeen, isFalse);
    await auth.completeOnboarding();
    expect(auth.onboardingSeen, isTrue);
    expect(repository.onboardingDone, isTrue);
  });

  test('signing in with the right password notifies listeners', () async {
    var notified = 0;
    auth.addListener(() => notified++);
    await auth.signIn(
      phone: FakeAuthRepository.phone,
      password: FakeAuthRepository.password,
    );
    expect(auth.isSignedIn, isTrue);
    expect(auth.user!.role, UserRole.customer);
    expect(notified, 1);
  });

  test('a wrong password fails and stays signed out', () async {
    await auth.restore();
    await expectLater(
      auth.signIn(phone: FakeAuthRepository.phone, password: 'nope1234'),
      throwsA(isA<ApiException>()),
    );
    expect(auth.isSignedIn, isFalse);
  });

  test('registering a technician signs in with no application yet', () async {
    await auth.register(
      name: 'سامي',
      phone: '01112345678',
      password: 'secret123',
      type: AccountType.technician,
    );
    expect(auth.user!.role, UserRole.technician);
    expect(auth.user!.technicianStatus, TechnicianStatus.notSubmitted);
    expect(auth.user!.canWork, isFalse);
  });

  test('signing out clears the user locally and in storage', () async {
    await auth.signIn(
      phone: FakeAuthRepository.phone,
      password: FakeAuthRepository.password,
    );
    await auth.signOut();
    expect(auth.isSignedIn, isFalse);
    expect(repository.signOutCount, 1);
    expect(repository.signedIn, isNull);
  });

  test('updating the name refreshes the cached user', () async {
    await auth.signIn(
      phone: FakeAuthRepository.phone,
      password: FakeAuthRepository.password,
    );
    await auth.updateName('منى');
    expect(auth.user!.name, 'منى');
    expect(repository.lastName, 'منى');
  });
}
