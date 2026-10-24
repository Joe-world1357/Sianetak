import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../domain/auth_models.dart';

enum AuthStatus { restoring, signedOut, signedIn }

/// Session state for the app: which demo account (if any) is signed in.
class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    // Named parameters cannot be private field formals, so assign them here.
    // ignore: prefer_initializing_formals
    : _repository = repository;

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.restoring;
  AppUser? _user;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Restores the account signed in at the last launch, if any.
  Future<void> restore() async {
    try {
      _apply(await _repository.currentUser());
    } catch (_) {
      _apply(null);
    }
  }

  Future<List<AppUser>> demoAccounts() => _repository.demoAccounts();

  Future<void> signInAs(String userId) async =>
      _apply(await _repository.signInAs(userId));

  /// Re-reads the account (its role changes when an application is approved).
  Future<void> refresh() => restore();

  Future<void> updateName(String name) async =>
      _apply(await _repository.updateName(name));

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
