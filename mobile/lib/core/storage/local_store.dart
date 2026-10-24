import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';

/// Where the local database and its files live: a JSON document plus binary blobs.
abstract class StorageBackend {
  Future<String?> readDocument();
  Future<void> writeDocument(String json);

  /// Keeps a copy of a document this version cannot read, instead of deleting it.
  Future<void> backupDocument(String raw);
  Future<Uint8List?> readBlob(String id);
  Future<void> writeBlob(String id, Uint8List bytes);
  Future<void> deleteBlob(String id);
}

/// Volatile storage, used by tests.
class MemoryStorageBackend implements StorageBackend {
  String? document;
  final Map<String, Uint8List> blobs = {};

  final List<String> backups = [];

  @override
  Future<String?> readDocument() async => document;

  @override
  Future<void> backupDocument(String raw) async => backups.add(raw);

  @override
  Future<void> writeDocument(String json) async => document = json;

  @override
  Future<Uint8List?> readBlob(String id) async => blobs[id];

  @override
  Future<void> writeBlob(String id, Uint8List bytes) async => blobs[id] = bytes;

  @override
  Future<void> deleteBlob(String id) async => blobs.remove(id);
}

typedef Row = Map<String, dynamic>;

/// The app's on-device database: a JSON document kept in memory and written through to
/// [StorageBackend] after every change (atomically, on the device). [LocalBackend] plays the
/// server's role on top of it, including validation and permission checks.
///
/// A fresh database holds only the service catalog and service areas: no accounts, requests
/// or other records exist until people create them in the app.
class LocalStore extends ChangeNotifier {
  LocalStore(this._backend, {required this.seed, DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  /// 4: real accounts (password hashes, sessions) and no sample records.
  static const schemaVersion = 4;

  /// [Proposed] How long a sign-in stays valid without being used.
  static const sessionLifetime = Duration(days: 30);

  final StorageBackend _backend;

  /// Builds a fresh database (catalog and service areas only).
  final Row Function(DateTime now) seed;
  final DateTime Function() now;
  Row _data = {};
  Future<void>? _opening;
  Future<void> _writes = Future.value();

  Future<void> open() => _opening ??= _load();

  Future<void> _load() async {
    final raw = await _backend.readDocument();
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Row;
        if (decoded['version'] == schemaVersion) {
          _data = decoded;
          return;
        }
      } on FormatException {
        // Unreadable: kept as a backup below, never silently deleted.
      } on TypeError {
        // Not a JSON object: same as above.
      }
      // An older or unknown format (such as the earlier demo build's sample data): keep a
      // copy, then start with a clean database.
      await _backend.backupDocument(raw);
    }
    _data = _fresh();
    await _persist();
  }

  /// The seed, round-tripped through JSON so it has exactly the types a reload would.
  Row _fresh() => jsonDecode(jsonEncode(seed(now()))) as Row;

  /// Rows of [table]; mutate them only inside [write].
  List<Row> table(String name) {
    final value = _data[name];
    if (value is List<Row>) return value;
    final rows = value == null
        ? <Row>[]
        : (value as List<dynamic>).cast<Row>().toList();
    _data[name] = rows;
    return rows;
  }

  Row? find(String tableName, String id) {
    for (final row in table(tableName)) {
      if (row['id'] == id) return row;
    }
    return null;
  }

  Row require(String tableName, String id, String notFoundCode) =>
      find(tableName, id) ??
      (throw ApiException(code: notFoundCode, statusCode: 404));

  Object? setting(String key) => _data[key];

  void setSetting(String key, Object? value) => _data[key] = value;

  /// The account signed in on this device, or null when signed out or the session lapsed.
  String? get sessionUserId {
    final session = _data['session'];
    if (session is! Map<String, dynamic>) return null;
    final expires = DateTime.tryParse(session['expiresAt'] as String? ?? '');
    if (expires == null || !now().isBefore(expires)) return null;
    return session['userId'] as String?;
  }

  Row? get sessionUser {
    final id = sessionUserId;
    final user = id == null ? null : find('users', id);
    return user == null || user['disabled'] == true ? null : user;
  }

  /// The signed-in user, or UNAUTHENTICATED; FORBIDDEN when the role is not in [roles].
  Row requireUser([Set<String>? roles]) {
    final user = sessionUser;
    if (user == null) {
      throw const ApiException(code: 'UNAUTHENTICATED', statusCode: 401);
    }
    if (roles != null && !roles.contains(user['role'])) {
      throw const ApiException(code: 'FORBIDDEN', statusCode: 403);
    }
    return user;
  }

  /// A short unique id with a readable prefix.
  String newId(String prefix) {
    final next = (_data['seq'] as int? ?? 0) + 1;
    _data['seq'] = next;
    return '$prefix-${next.toRadixString(36)}-${now().microsecondsSinceEpoch.toRadixString(36)}';
  }

  /// Applies [change] and saves. Writes are serialised so the file is never interleaved.
  Future<T> write<T>(T Function() change) async {
    await open();
    final result = change();
    await _persist();
    notifyListeners();
    return result;
  }

  /// Starts (or with null, ends) the device session. Sliding: renewed on each launch.
  void setSession(String? userId) => _data['session'] = userId == null
      ? null
      : {
          'userId': userId,
          'expiresAt': now().add(sessionLifetime).toUtc().toIso8601String(),
        };

  Future<void> _persist() {
    final json = jsonEncode(_data);
    return _writes = _writes.then((_) => _backend.writeDocument(json));
  }

  Future<Uint8List?> readBlob(String id) => _backend.readBlob(id);
  Future<void> writeBlob(String id, Uint8List bytes) =>
      _backend.writeBlob(id, bytes);
  Future<void> deleteBlob(String id) => _backend.deleteBlob(id);
}
