import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/app.dart';
import 'package:sianetak_customer/core/locale/locale_controller.dart';
import 'package:sianetak_customer/features/auth/application/auth_controller.dart';
import 'package:sianetak_customer/features/auth/data/token_store.dart';
import 'package:sianetak_customer/features/catalog/data/catalog_repository.dart';

import 'fakes.dart';

class TestHarness {
  TestHarness({
    CatalogRepository? catalog,
    FakeAuthRepository? auth,
    FakeRequestsRepository? requests,
    FakeMediaRepository? media,
    FakeTechnicianRepository? technician,
    FakeAdminRepository? admin,
    FakeImagePicker? imagePicker,
    FakeLocationService? location,
    Locale locale = LocaleController.arabic,
  }) : catalog = catalog ?? FakeCatalogRepository(),
       authRepository = auth ?? FakeAuthRepository(),
       requests = requests ?? FakeRequestsRepository(),
       media = media ?? FakeMediaRepository(),
       technician = technician ?? FakeTechnicianRepository(),
       admin = admin ?? FakeAdminRepository(),
       imagePicker = imagePicker ?? FakeImagePicker(),
       location = location ?? FakeLocationService(),
       locale = LocaleController(initial: locale) {
    authController = AuthController(
      repository: authRepository,
      tokenStore: InMemoryTokenStore(),
    );
  }

  final CatalogRepository catalog;
  final FakeAuthRepository authRepository;
  final FakeRequestsRepository requests;
  final FakeMediaRepository media;
  final FakeTechnicianRepository technician;
  final FakeAdminRepository admin;
  final FakeImagePicker imagePicker;
  final FakeLocationService location;
  final LocaleController locale;
  late final AuthController authController;

  Widget get app => SianetakApp(
    catalog: catalog,
    auth: authController,
    locale: locale,
    requests: requests,
    media: media,
    technician: technician,
    admin: admin,
    imagePicker: imagePicker,
    location: location,
  );
}

/// Pumps the app and settles the initial load.
Future<TestHarness> pumpApp(WidgetTester tester, {TestHarness? harness}) async {
  final h = harness ?? TestHarness();
  await tester.pumpWidget(h.app);
  await tester.pumpAndSettle();
  return h;
}
