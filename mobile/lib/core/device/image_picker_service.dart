import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/media/domain/media_models.dart';

enum ImageOrigin { camera, gallery }

/// The user (or the OS) refused camera or photo-library access.
class ImagePermissionDenied implements Exception {
  const ImagePermissionDenied();
}

/// Picks one image from the camera or gallery. Returns null if the user cancels.
abstract class ImagePickerService {
  Future<PickedImage?> pick(ImageOrigin origin);
}

class DeviceImagePicker implements ImagePickerService {
  DeviceImagePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pick(ImageOrigin origin) async {
    try {
      // Resizing re-encodes the photo, which keeps uploads small on mobile networks.
      final file = await _picker.pickImage(
        source: origin == ImageOrigin.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 80,
      );
      if (file == null) return null;
      return PickedImage(bytes: await file.readAsBytes(), name: file.name);
    } on PlatformException catch (e) {
      if (e.code.contains('access_denied')) throw const ImagePermissionDenied();
      rethrow;
    }
  }
}
