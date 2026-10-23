import 'package:flutter/widgets.dart';

import '../features/admin/data/admin_repository.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/media/data/media_repository.dart';
import '../features/requests/data/requests_repository.dart';
import '../features/technician/data/technician_repository.dart';
import 'device/image_picker_service.dart';
import 'device/location_service.dart';
import 'locale/locale_controller.dart';

/// Dependency container for the widget tree; swapped for fakes in tests.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.catalog,
    required this.auth,
    required this.locale,
    required this.requests,
    required this.media,
    required this.technician,
    required this.admin,
    required this.imagePicker,
    required this.location,
    required super.child,
  });

  final CatalogRepository catalog;
  final AuthController auth;
  final LocaleController locale;
  final RequestsRepository requests;
  final MediaRepository media;
  final TechnicianRepository technician;
  final AdminRepository admin;
  final ImagePickerService imagePicker;
  final LocationService location;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      catalog != oldWidget.catalog ||
      auth != oldWidget.auth ||
      locale != oldWidget.locale ||
      requests != oldWidget.requests ||
      media != oldWidget.media ||
      technician != oldWidget.technician ||
      admin != oldWidget.admin ||
      imagePicker != oldWidget.imagePicker ||
      location != oldWidget.location;
}
