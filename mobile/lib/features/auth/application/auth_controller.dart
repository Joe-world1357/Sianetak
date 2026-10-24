import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

enum AuthStatus { restoring, signedOut, signedIn }

/// Session state for the app: which local account (if any) is signed in on this device.
class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    // Named parameters cannot be private field formals, so assign them here.
    // ignore: prefer_initializing_formals
    : _repository = repository;

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.restoring;
  AppUser? _user;
  bool _onboardingSeen = true;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// False only on a device that has never finished the welcome screens.
  bool get onboardingSeen => _onboardingSeen;

  /// Restores the account signed in at the last launch, if its session is still valid.
  Future<void> restore() async {
    try {
      _onboardingSeen = await _repository.onboardingSeen();
      _apply(await _repository.currentUser(renew: true));
    } catch (_) {
      _apply(null);
    }
  }

  Future<void> completeOnboarding() async {
    _onboardingSeen = true;
    notifyListeners();
    await _repository.markOnboardingSeen();
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required AccountType type,
  }) async => _apply(
    await _repository.register(
      name: name,
      phone: phone,
      password: password,
      type: type,
    ),
  );

  Future<void> signIn({
    required String phone,
    required String password,
  }) async =>
      _apply(await _repository.signIn(phone: phone, password: password));

  Future<bool> hasAdmin() => _repository.hasAdmin();

  Future<void> setupAdmin({
    required String name,
    required String phone,
    required String password,
  }) async => _apply(
    await _repository.setupAdmin(name: name, phone: phone, password: password),
  );

  Future<AppUser> createAdmin({
    required String name,
    required String phone,
    required String password,
  }) => _repository.createAdmin(name: name, phone: phone, password: password);

  /// Re-reads the account (a technician's status changes when an admin reviews them).
  Future<void> refresh() async {
    try {
      final user = await _repository.currentUser();
      if (user?.id != _user?.id ||
          user?.technicianStatus != _user?.technicianStatus ||
          user?.name != _user?.name) {
        _apply(user);
      }
    } catch (_) {
      // Keep the current state; the next action will surface any problem.
    }
  }

  Future<void> updateName(String name) async =>
      _apply(await _repository.updateName(name));

  Future<void> changePassword({
    required String current,
    required String next,
  }) => _repository.changePassword(current: current, next: next);

  Future<void> signOut() async {
    _apply(null);
    await _repository.signOut();
  }

  void _apply(AppUser? user) {
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }
}
