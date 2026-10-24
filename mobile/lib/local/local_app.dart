import 'package:flutter/widgets.dart';

import '../app.dart';
import '../core/device/image_picker_service.dart';
import '../core/device/location_service.dart';
import '../core/locale/locale_controller.dart';
import '../core/security/password_hasher.dart';
import '../core/storage/local_store.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/jobs/data/jobs_repository.dart';
import '../features/media/data/media_repository.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/requests/data/requests_repository.dart';
import '../features/technician/data/technician_repository.dart';
import 'local_backend.dart';
import 'initial_data.dart';

/// Wires the app to the on-device database. Used by `main` and by end-to-end tests.
class LocalApp {
  LocalApp(
    StorageBackend storage, {
    required this.imagePicker,
    required this.location,
    Locale locale = LocaleController.arabic,
    DateTime Function()? clock,
    PasswordHasher? hasher,
  }) : store = LocalStore(storage, seed: buildInitialData, clock: clock),
       locale = LocaleController(initial: locale) {
    backend = LocalBackend(store, hasher: hasher);
    auth = AuthController(repository: LocalAuthRepository(backend));
    // Keeps the signed-in account current (for example a technician's review status).
    store.addListener(auth.refresh);
  }

  final LocalStore store;
  final LocaleController locale;
  final ImagePickerService imagePicker;
  final LocationService location;
  late final LocalBackend backend;
  late final AuthController auth;

  /// Opens the database and restores the last signed-in account.
  Future<void> start() async {
    await store.open();
    await auth.restore();
  }

  Widget build() => SianetakApp(
    catalog: LocalCatalogRepository(backend),
    auth: auth,
    locale: locale,
    requests: LocalRequestsRepository(backend),
    media: LocalMediaRepository(backend),
    technician: LocalTechnicianRepository(backend),
    admin: LocalAdminRepository(backend),
    imagePicker: imagePicker,
    location: location,
    jobs: LocalJobsRepository(backend),
    notifications: LocalNotificationsRepository(backend),
    changes: store,
  );
}
