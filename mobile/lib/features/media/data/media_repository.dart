import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../domain/media_models.dart';

enum MediaPurpose { requestPhoto, technicianDocument }

/// Private uploads. Files are only readable through authenticated requests.
abstract class MediaRepository {
  Future<UploadedMedia> upload(MediaPurpose purpose, PickedImage file);
  Future<void> remove(String id);
  Future<Uint8List> fetch(String id);
}

class HttpMediaRepository implements MediaRepository {
  HttpMediaRepository(this._api);

  final ApiClient _api;

  @override
  Future<UploadedMedia> upload(MediaPurpose purpose, PickedImage file) async =>
      UploadedMedia.fromJson(
        await _api.uploadFile(
          '/media',
          fields: {
            'purpose': purpose == MediaPurpose.requestPhoto
                ? 'request_photo'
                : 'technician_document',
          },
          bytes: file.bytes,
          filename: file.name,
        ),
      );

  @override
  Future<void> remove(String id) =>
      _api.delete('/media/${Uri.encodeComponent(id)}', authenticated: true);

  @override
  Future<Uint8List> fetch(String id) =>
      _api.getBytes('/media/${Uri.encodeComponent(id)}/content');
}
