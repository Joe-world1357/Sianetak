import 'package:flutter/widgets.dart';

import '../app.dart';
import '../core/device/image_picker_service.dart';
import '../core/device/location_service.dart';
import '../core/locale/locale_controller.dart';
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
import 'demo_backend.dart';
import 'demo_seed.dart';

/// Wires the app to the on-device demo database. Used by `main` and by end-to-end tests.
class DemoApp {
  DemoApp(
    StorageBackend storage, {
    required this.imagePicker,
    required this.location,
    Locale locale = LocaleController.arabic,
    DateTime Function()? clock,
  }) : store = LocalStore(storage, seed: buildDemoSeed, clock: clock),
       locale = LocaleController(initial: locale) {
    backend = DemoBackend(store);
    auth = AuthController(repository: LocalAuthRepository(backend));
  }

  final LocalStore store;
  final LocaleController locale;
  final ImagePickerService imagePicker;
  final LocationService location;
  late final DemoBackend backend;
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
    resetDemo: store.reset,
  );
}
