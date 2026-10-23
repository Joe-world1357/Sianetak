import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/token_store.dart';
import '../domain/auth_models.dart';

enum AuthStatus { restoring, signedOut, signedIn }

/// Session state for the app. Business rules (limits, expiry, roles) live on the server;
/// this class only keeps tokens and exposes the signed-in user.
class AuthController extends ChangeNotifier implements AccessTokenProvider {
  AuthController({
    required AuthRepository repository,
    required TokenStore tokenStore,
  }) // Named parameters cannot be private field formals, so assign them here.
    // ignore: prefer_initializing_formals
    : _repository = repository,
       // ignore: prefer_initializing_formals
       _tokenStore = tokenStore;

  final AuthRepository _repository;
  final TokenStore _tokenStore;

  AuthStatus _status = AuthStatus.restoring;
  AppUser? _user;
  String? _accessToken;
  Future<bool>? _refreshing;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  @override
  String? get accessToken => _accessToken;

  /// Restores a previous session from the stored refresh token, if any.
  Future<void> restore() async {
    final ok = await refreshAccessToken();
    if (!ok && _status == AuthStatus.restoring) _setSignedOut();
  }

  Future<OtpChallenge> requestOtp(String phoneE164) =>
      _repository.requestOtp(phoneE164);

  Future<AuthSession> verifyOtp(OtpChallenge challenge, String code) async {
    final session = await _repository.verifyOtp(challenge, code);
    await _applySession(session);
    return session;
  }

  @override
  Future<bool> refreshAccessToken() {
    // Coalesce concurrent refreshes into one request.
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    final stored = await _tokenStore.readRefreshToken();
    if (stored == null) {
      if (_status != AuthStatus.signedOut) _setSignedOut();
      return false;
    }
    try {
      await _applySession(await _repository.refresh(stored));
      return true;
    } on ApiException catch (e) {
      if (e.code == ApiException.network) {
        // Keep the stored token; the user may be offline. Stay signed out until it works.
        if (_status == AuthStatus.restoring) _setSignedOut(clearToken: false);
        return false;
      }
      _setSignedOut();
      return false;
    }
  }

  Future<void> updateName(String name) async {
    _user = await _repository.updateName(name);
    notifyListeners();
  }

  Future<void> signOut() async {
    final stored = await _tokenStore.readRefreshToken();
    _setSignedOut();
    if (stored != null) {
      try {
        await _repository.logout(stored);
      } catch (_) {
        // Local sign-out already happened; the server token expires on its own.
      }
    }
  }

  Future<void> _applySession(AuthSession session) async {
    await _tokenStore.writeRefreshToken(session.refreshToken);
    _accessToken = session.accessToken;
    _user = session.user;
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  void _setSignedOut({bool clearToken = true}) {
    if (clearToken) _tokenStore.clear();
    _accessToken = null;
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
