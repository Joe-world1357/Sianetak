import 'dart:typed_data';

import '../../../local/local_backend.dart';
import '../domain/media_models.dart';

enum MediaPurpose { requestPhoto, technicianDocument }

/// Private files, kept in the app's own storage and readable only by permitted accounts.
abstract class MediaRepository {
  Future<UploadedMedia> upload(MediaPurpose purpose, PickedImage file);
  Future<void> remove(String id);
  Future<Uint8List> fetch(String id);
}

class LocalMediaRepository implements MediaRepository {
  LocalMediaRepository(this._backend);

  final LocalBackend _backend;

  @override
  Future<UploadedMedia> upload(MediaPurpose purpose, PickedImage file) async =>
      UploadedMedia.fromJson(
        await _backend.uploadMedia(
          purpose == MediaPurpose.requestPhoto
              ? 'request_photo'
              : 'technician_document',
          file.bytes,
        ),
      );

  @override
  Future<void> remove(String id) => _backend.removeMedia(id);

  @override
  Future<Uint8List> fetch(String id) => _backend.mediaContent(id);
}
