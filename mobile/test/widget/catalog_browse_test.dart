import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/catalog/domain/catalog_models.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('a customer sees Arabic categories in an RTL layout', (
    tester,
  ) async {
    await pumpApp(tester, harness: TestHarness(signedIn: true));

    expect(find.text('سباكة'), findsOneWidget);
    expect(find.text('ما الخدمة التي تحتاجها؟'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('سباكة'))),
      TextDirection.rtl,
    );
  });

  testWidgets('switching language re-renders in English, left to right', (
    tester,
  ) async {
    await pumpApp(tester, harness: TestHarness(signedIn: true));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('What needs fixing?'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Plumbing'))),
      TextDirection.ltr,
    );
  });

  testWidgets('shows a loading indicator and then the data', (tester) async {
    final harness = TestHarness(signedIn: true);
    await harness.authController.restore();
    await tester.pumpWidget(harness.app);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('سباكة'), findsOneWidget);
  });

  testWidgets('shows an empty state when no categories are configured', (
    tester,
  ) async {
    await pumpApp(
      tester,
      harness: TestHarness(
        signedIn: true,
        catalog: FakeCatalogRepository(categories: []),
      ),
    );
    expect(
      find.text('لا توجد خدمات متاحة حاليًا. حاول لاحقًا.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a load error with a retry that reloads', (tester) async {
    final catalog = FakeCatalogRepository(
      error: const ApiException(code: ApiException.network),
    );
    await pumpApp(
      tester,
      harness: TestHarness(signedIn: true, catalog: catalog),
    );

    expect(find.text('تعذّر تحميل البيانات'), findsOneWidget);
    expect(
      find.text('تعذّر الوصول إلى البيانات. حاول مرة أخرى.'),
      findsOneWidget,
    );

    catalog.error = null;
    await tester.tap(find.text('حاول مرة أخرى'));
    await tester.pumpAndSettle();
    expect(find.text('سباكة'), findsOneWidget);
    expect(catalog.listCalls, 2);
  });

  testWidgets(
    'opens a category and then a service detail with pricing guidance',
    (tester) async {
      await pumpApp(tester, harness: TestHarness(signedIn: true));

      await tester.tap(find.text('سباكة'));
      await tester.pumpAndSettle();
      expect(find.text('إصلاح تسريب'), findsOneWidget);
      expect(find.text('السعر يُحدَّد بعد المعاينة'), findsWidgets);

      await tester.tap(find.text('إصلاح تسريب'));
      await tester.pumpAndSettle();
      expect(find.text('التسعير'), findsOneWidget);
      expect(find.textContaining('سيعاين الفني المشكلة'), findsOneWidget);
      expect(find.text('اطلب الخدمة'), findsOneWidget);
    },
  );

  testWidgets(
    'shows an approved indicative price range instead of inspection copy',
    (tester) async {
      final catalog = FakeCatalogRepository(
        services: [
          service(
            slug: 'fixed-price',
            ar: 'تركيب حنفية',
            en: 'Tap installation',
            pricing: const PricingGuidance.indicative(
              minMinor: 15000,
              maxMinor: 30000,
            ),
          ),
        ],
      );
      await pumpApp(
        tester,
        harness: TestHarness(signedIn: true, catalog: catalog),
      );

      await tester.tap(find.text('سباكة'));
      await tester.pumpAndSettle();
      expect(find.textContaining('سعر تقديري'), findsOneWidget);
      expect(find.text('السعر يُحدَّد بعد المعاينة'), findsNothing);
    },
  );

  testWidgets('shows an empty state for a category with no services', (
    tester,
  ) async {
    await pumpApp(
      tester,
      harness: TestHarness(
        signedIn: true,
        catalog: FakeCatalogRepository(services: []),
      ),
    );
    await tester.tap(find.text('سباكة'));
    await tester.pumpAndSettle();
    expect(
      find.text('لا توجد خدمات متاحة في هذا القسم حاليًا.'),
      findsOneWidget,
    );
  });

  testWidgets('layout survives large text scaling without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 690 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final harness = TestHarness(signedIn: true);
    await harness.authController.restore();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: harness.app,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('سباكة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
