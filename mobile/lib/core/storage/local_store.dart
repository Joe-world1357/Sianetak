import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';

/// Where the demo database and its files live: a JSON document plus binary blobs.
abstract class StorageBackend {
  Future<String?> readDocument();
  Future<void> writeDocument(String json);
  Future<Uint8List?> readBlob(String id);
  Future<void> writeBlob(String id, Uint8List bytes);
  Future<void> deleteBlob(String id);
  Future<void> clear();
}

/// Volatile storage, used by tests.
class MemoryStorageBackend implements StorageBackend {
  String? document;
  final Map<String, Uint8List> blobs = {};

  @override
  Future<String?> readDocument() async => document;

  @override
  Future<void> writeDocument(String json) async => document = json;

  @override
  Future<Uint8List?> readBlob(String id) async => blobs[id];

  @override
  Future<void> writeBlob(String id, Uint8List bytes) async => blobs[id] = bytes;

  @override
  Future<void> deleteBlob(String id) async => blobs.remove(id);

  @override
  Future<void> clear() async {
    document = null;
    blobs.clear();
  }
}

typedef Row = Map<String, dynamic>;

/// The standalone demo's database: a JSON document kept in memory and written through to
/// [StorageBackend] after every change. Repositories play the server's role on top of it,
/// including permission checks, so the screens behave as they did against the API.
class LocalStore extends ChangeNotifier {
  LocalStore(this._backend, {required this.seed, DateTime Function()? clock})
    : now = clock ?? DateTime.now;

  static const schemaVersion = 3;

  final StorageBackend _backend;

  /// Builds a fresh database (demo accounts, catalog, sample records).
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
        // Corrupt file: start over with fresh demo data.
      }
    }
    await _backend.clear();
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

  /// Signed-in demo account, or null for a guest.
  String? get sessionUserId => _data['session'] as String?;

  Row? get sessionUser =>
      sessionUserId == null ? null : find('users', sessionUserId!);

  /// The signed-in user, or UNAUTHENTICATED.
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

  void setSession(String? userId) => _data['session'] = userId;

  Future<void> _persist() {
    final json = jsonEncode(_data);
    return _writes = _writes.then((_) => _backend.writeDocument(json));
  }

  Future<Uint8List?> readBlob(String id) => _backend.readBlob(id);
  Future<void> writeBlob(String id, Uint8List bytes) =>
      _backend.writeBlob(id, bytes);
  Future<void> deleteBlob(String id) => _backend.deleteBlob(id);

  /// Wipes everything and re-seeds the demo data. Keeps nobody signed in.
  Future<void> reset() async {
    await open();
    await _writes;
    await _backend.clear();
    _data = _fresh();
    await _persist();
    notifyListeners();
  }
}
