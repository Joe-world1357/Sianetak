import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_scope.dart';
import 'core/device/image_picker_service.dart';
import 'core/device/location_service.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/data/admin_repository.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/catalog/data/catalog_repository.dart';
import 'features/catalog/presentation/home_screen.dart';
import 'features/media/data/media_repository.dart';
import 'features/requests/data/requests_repository.dart';
import 'features/technician/data/technician_repository.dart';
import 'l10n/generated/app_localizations.dart';

class SianetakApp extends StatelessWidget {
  const SianetakApp({
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

  @override
  Widget build(BuildContext context) {
    return AppScope(
      catalog: catalog,
      auth: auth,
      locale: locale,
      requests: requests,
      media: media,
      technician: technician,
      admin: admin,
      imagePicker: imagePicker,
      location: location,
      child: ListenableBuilder(
        listenable: locale,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: locale.locale,
          supportedLocales: LocaleController.supported,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Directionality (RTL for Arabic) follows the locale automatically.
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
