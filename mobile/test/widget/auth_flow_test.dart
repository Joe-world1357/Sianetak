import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';

void main() {
  testWidgets('first launch shows the welcome pages, then sign-in', (
    tester,
  ) async {
    final harness = await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(onboardingDone: false)),
    );
    expect(find.text('صيانة بيتك في مكان واحد'), findsOneWidget);
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(harness.authRepository.onboardingDone, isTrue);
  });

  testWidgets('signing in lands in the customer navigation', (tester) async {
    final harness = await pumpApp(tester);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await signIn(tester);
    expect(harness.authController.isSignedIn, isTrue);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
  });

  testWidgets('a wrong password shows an error and stays on sign-in', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await signIn(tester, password: 'wrong-pass1');
    expect(harness.authController.isSignedIn, isFalse);
    expect(find.text('رقم الموبايل أو كلمة المرور غير صحيحة.'), findsOneWidget);
  });

  testWidgets('sign-in validates the phone number and password', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'دخول'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أدخل رقم موبايل مصري صحيح'), findsOneWidget);
    expect(find.text('أدخل كلمة المرور.'), findsOneWidget);
  });

  testWidgets('sign-up creates a customer account and signs it in', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await tester.tap(find.text('أنشئ حساباً'));
    await tester.pumpAndSettle();
    expect(find.text('إنشاء حساب'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'منى حسن');
    await tester.enterText(fields.at(1), '01112345678');
    await tester.enterText(fields.at(2), 'short');
    await tester.enterText(fields.at(3), 'other');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'إنشاء الحساب'));
    expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);
    expect(harness.authController.isSignedIn, isFalse);

    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'secret123');
    await tapVisible(tester, find.widgetWithText(FilledButton, 'إنشاء الحساب'));
    expect(harness.authController.user?.name, 'منى حسن');
    expect(harness.authController.user?.role, UserRole.customer);
    expect(find.text('طلباتي'), findsOneWidget);
  });

  testWidgets('a new technician sees only the application until approved', (
    tester,
  ) async {
    await pumpApp(
      tester,
      harness: TestHarness(
        auth: FakeAuthRepository(
          role: UserRole.technician,
          technicianStatus: TechnicianStatus.notSubmitted,
        ),
      ),
    );
    await signIn(tester);
    expect(find.text('طلب الانضمام'), findsWidgets);
    expect(find.text('العروض'), findsNothing);
    expect(find.text('أعمالي'), findsNothing);
  });

  testWidgets('an approved technician gets offers and jobs', (tester) async {
    await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(role: UserRole.technician)),
    );
    await signIn(tester);
    expect(find.text('العروض'), findsOneWidget);
    expect(find.text('أعمالي'), findsWidgets);
    expect(find.text('الرئيسية'), findsNothing);
  });

  testWidgets('administrator setup is offered only while none exists', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('إعداد حساب المسؤول'), findsNothing);
  });

  testWidgets('the first administrator is set up once from sign-in', (
    tester,
  ) async {
    final harness = await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(adminExists: false)),
    );
    await tapVisible(tester, find.text('إعداد حساب المسؤول'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'مدير النظام');
    await tester.enterText(fields.at(1), '01222222222');
    await tester.enterText(fields.at(2), 'admin1234');
    await tester.enterText(fields.at(3), 'admin1234');
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'إنشاء حساب المسؤول'),
    );
    expect(harness.authController.user?.role, UserRole.admin);
    expect(find.text('لوحة التشغيل'), findsWidgets);
  });

  testWidgets('profile saves a name, and sign-out asks first', (tester) async {
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
    await tapVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'تسجيل الخروج'),
    );
    expect(find.text('تسجيل الخروج؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
    await tester.pumpAndSettle();
    expect(harness.authController.isSignedIn, isFalse);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('a signed-in user can change their password', (tester) async {
    final harness = await pumpApp(tester);
    await signIn(tester);
    await openProfile(tester);
    await tapVisible(tester, find.text('تغيير كلمة المرور'));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'secret123');
    await tester.enterText(fields.at(1), 'newpass99');
    await tester.enterText(fields.at(2), 'newpass99');
    await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
    await tester.pumpAndSettle();
    expect(harness.authRepository.currentPassword, 'newpass99');
    expect(find.text('تم تغيير كلمة المرور.'), findsOneWidget);
  });

  testWidgets('the sign-in screen works in English and LTR too', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      find.text('Welcome back. Use your mobile number and password.'),
      findsOneWidget,
    );
    expect(
      Directionality.of(tester.element(find.text('Mobile number'))),
      TextDirection.ltr,
    );
  });
}
