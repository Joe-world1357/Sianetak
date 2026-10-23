import 'dart:typed_data';

/// A file the user picked on the device, before upload.
class PickedImage {
  const PickedImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

/// A file stored privately on the server.
class UploadedMedia {
  const UploadedMedia({
    required this.id,
    required this.contentType,
    required this.byteSize,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => UploadedMedia(
    id: json['id'] as String,
    contentType: json['contentType'] as String? ?? 'application/octet-stream',
    byteSize: json['byteSize'] as int? ?? 0,
  );

  final String id;
  final String contentType;
  final int byteSize;

  bool get isImage => contentType.startsWith('image/');
}
