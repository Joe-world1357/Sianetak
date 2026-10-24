import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/device/image_picker_service.dart';
import 'core/device/location_service.dart';
import 'core/storage/file_storage_backend.dart';
import 'core/storage/local_store.dart';
import 'local/local_app.dart';

/// Standalone demo: all data lives on the device; no server, network or SMS needed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final demo = LocalApp(
    // The browser build (handy for previews) keeps data in memory only.
    kIsWeb ? MemoryStorageBackend() : FileStorageBackend(),
    imagePicker: DeviceImagePicker(),
    location: DeviceLocationService(),
  );
  await demo.start();
  runApp(demo.build());
}
