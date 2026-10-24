import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'local_store.dart';

/// Keeps the demo database in the app's private documents folder on the device.
class FileStorageBackend implements StorageBackend {
  Directory? _root;

  Future<Directory> _dir() async {
    final root = _root ??= Directory(
      '${(await getApplicationDocumentsDirectory()).path}/sianetak_demo',
    );
    if (!await root.exists()) await root.create(recursive: true);
    return root;
  }

  Future<File> _document() async => File('${(await _dir()).path}/db.json');

  Future<File> _blob(String id) async {
    final media = Directory('${(await _dir()).path}/media');
    if (!await media.exists()) await media.create();
    // Ids are generated locally, but never let one escape the folder.
    return File(
      '${media.path}/${id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')}',
    );
  }

  @override
  Future<String?> readDocument() async {
    final file = await _document();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> writeDocument(String json) async {
    // Write then rename, so a crash mid-write never leaves a half-written database.
    final file = await _document();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(json, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<Uint8List?> readBlob(String id) async {
    final file = await _blob(id);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> writeBlob(String id, Uint8List bytes) async =>
      (await _blob(id)).writeAsBytes(bytes, flush: true);

  @override
  Future<void> deleteBlob(String id) async {
    final file = await _blob(id);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> clear() async {
    final root = await _dir();
    if (await root.exists()) await root.delete(recursive: true);
    _root = null;
  }
}
