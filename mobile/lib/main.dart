import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/device/image_picker_service.dart';
import 'core/device/location_service.dart';
import 'core/locale/locale_controller.dart';
import 'core/network/api_client.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/token_store.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/media/data/media_repository.dart';
import 'features/requests/data/requests_repository.dart';
import 'features/technician/data/technician_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  final config = AppConfig.fromEnvironment();
  final api = ApiClient(baseUrl: config.apiBaseUrl);
  final auth = AuthController(
    repository: HttpAuthRepository(api),
    tokenStore: SecureTokenStore(),
  );
  api.tokenProvider = auth;
  // Restore in the background; guests can browse immediately.
  auth.restore();

  runApp(
    SianetakApp(
      catalog: HttpCatalogRepository(api),
      auth: auth,
      locale: LocaleController(),
      requests: HttpRequestsRepository(api),
      media: HttpMediaRepository(api),
      technician: HttpTechnicianRepository(api),
      admin: HttpAdminRepository(api),
      imagePicker: DeviceImagePicker(),
      location: DeviceLocationService(),
    ),
  );
}
