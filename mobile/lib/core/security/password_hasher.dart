import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashes, stored as
/// `pbkdf2-sha256$<iterations>$<salt b64>$<hash b64>`. Plaintext passwords are never stored.
class PasswordHasher {
  const PasswordHasher({
    this.iterations = defaultIterations,
    this.background = true,
  });

  /// Tuned so hashing takes well under a second on a mid-range phone, off the UI thread.
  static const defaultIterations = 60000;
  static const _scheme = 'pbkdf2-sha256';
  static const _saltBytes = 16;
  static const _keyBytes = 32;

  final int iterations;

  /// Runs the key derivation in a background isolate (off in widget tests, which fake time).
  final bool background;

  Future<Uint8List> _run((List<int>, List<int>, int, int) args) async =>
      background ? compute(_derive, args) : _derive(args);

  Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
      List.generate(_saltBytes, (_) => random.nextInt(256)),
    );
    final key = await _run((
      utf8.encode(password),
      salt,
      iterations,
      _keyBytes,
    ));
    return '$_scheme\$$iterations\$${base64Encode(salt)}\$${base64Encode(key)}';
  }

  /// True when [password] matches [stored]. Unknown or malformed hashes never match.
  Future<bool> verify(String password, String stored) async {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = await _run((
      utf8.encode(password),
      salt,
      rounds,
      expected.length,
    ));
    return _constantTimeEquals(actual, expected);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2 (RFC 8018) with HMAC-SHA256. Top-level so it can run in a background isolate.
Uint8List _derive((List<int>, List<int>, int, int) args) {
  final (password, salt, iterations, length) = args;
  final hmac = Hmac(sha256, password);
  final out = BytesBuilder();
  for (var block = 1; out.length < length; block++) {
    final first = Uint8List(salt.length + 4)
      ..setAll(0, salt)
      ..buffer.asByteData().setUint32(salt.length, block);
    var u = hmac.convert(first).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.sublistView(out.takeBytes(), 0, length);
}
