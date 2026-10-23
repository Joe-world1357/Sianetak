import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the refresh token. The short-lived access token is kept in memory only.
abstract class TokenStore {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> clear();
}

/// Keychain (iOS) / Keystore-backed encrypted storage (Android).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'sianetak.refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readRefreshToken() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      // Corrupt or unavailable keystore: treat as signed out rather than crash.
      return null;
    }
  }

  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class InMemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> readRefreshToken() async => _token;

  @override
  Future<void> writeRefreshToken(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
