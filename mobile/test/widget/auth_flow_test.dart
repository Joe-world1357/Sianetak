import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('a guest picks a demo account and lands in its navigation', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    expect(find.text('اختر حساب التجربة'), findsOneWidget);
    expect(find.text('عميل'), findsOneWidget);

    await tester.tap(find.text('عميل'));
    await tester.pumpAndSettle();
    expect(harness.authController.isSignedIn, isTrue);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
  });

  testWidgets('each role gets its own tabs', (tester) async {
    await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(role: UserRole.technician)),
    );
    await signIn(tester);
    expect(find.text('العروض'), findsOneWidget);
    expect(find.text('أعمالي'), findsWidgets);
    expect(find.text('الرئيسية'), findsNothing);
  });

  testWidgets('profile shows the role, saves a name and signs out', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await signIn(tester);
    await openProfile(tester);
    expect(find.text('عميل'), findsOneWidget);
    expect(find.textContaining('01012345678'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'أحمد محمد');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(harness.authRepository.lastName, 'أحمد محمد');
    expect(find.text('تم حفظ البيانات.'), findsOneWidget);

    await dismissSnackBars(tester);
    await tapVisible(tester, find.text('تسجيل الخروج'));
    expect(harness.authController.isSignedIn, isFalse);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });

  testWidgets(
    'a guest is sent to sign-in from the service detail request button',
    (tester) async {
      final harness = await pumpApp(tester);
      await tester.tap(find.text('سباكة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إصلاح تسريب'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('سجّل الدخول لطلب الخدمة'));
      await tester.pumpAndSettle();
      expect(find.text('اختر حساب التجربة'), findsOneWidget);
      await tester.tap(find.text('عميل'));
      await tester.pumpAndSettle();

      // Signed in, the customer continues straight into the request flow.
      expect(harness.authController.isSignedIn, isTrue);
      expect(find.text('صف المشكلة'), findsOneWidget);
    },
  );

  testWidgets('the sign-in screen works in English and LTR too', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();
    expect(find.text('Choose a demo account'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Customer'))),
      TextDirection.ltr,
    );
  });
}
