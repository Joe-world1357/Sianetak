import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

Future<void> openSignIn(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
}

Future<void> enterPhone(WidgetTester tester, String phone) async {
  await tester.enterText(find.byType(TextFormField), phone);
  await tester.tap(find.text('إرسال الرمز'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer signs in with a phone number and OTP', (tester) async {
    final harness = await pumpApp(tester);
    await openSignIn(tester);

    expect(find.text('تسجيل الدخول'), findsWidgets);
    await enterPhone(tester, '01012345678');

    // The OTP step shows the number it was sent to, in local form.
    expect(find.textContaining('01012345678'), findsOneWidget);
    expect(harness.authRepository.requestCount, 1);

    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pumpAndSettle();

    expect(harness.authController.isSignedIn, isTrue);
    expect(find.text('أهلًا بك! تم تسجيل الدخول.'), findsOneWidget);
    // Back on the catalog, the account icon has replaced the sign-in icon.
    expect(find.byIcon(Icons.account_circle), findsOneWidget);
  });

  testWidgets('normalizes an Arabic-Indic number before sending it', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await openSignIn(tester);
    await enterPhone(tester, '٠١٠١٢٣٤٥٦٧٨');
    expect(harness.authRepository.requestCount, 1);
    expect(find.textContaining('01012345678'), findsOneWidget);
  });

  testWidgets('rejects an invalid phone number before calling the server', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await openSignIn(tester);
    await enterPhone(tester, '0221234567');

    expect(
      find.text('أدخل رقم موبايل مصري صحيح (مثال: 01012345678).'),
      findsOneWidget,
    );
    expect(harness.authRepository.requestCount, 0);
  });

  testWidgets('shows the server message when sign-in is unavailable', (
    tester,
  ) async {
    final auth = FakeAuthRepository()
      ..requestError = const ApiException(
        code: 'OTP_DELIVERY_UNAVAILABLE',
        statusCode: 503,
      );
    await pumpApp(tester, harness: TestHarness(auth: auth));
    await openSignIn(tester);
    await enterPhone(tester, '01012345678');
    expect(
      find.text('تسجيل الدخول برسائل SMS غير متاح حاليًا.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows remaining attempts for a wrong code and stays on the screen',
    (tester) async {
      final harness = await pumpApp(tester);
      await openSignIn(tester);
      await enterPhone(tester, '01012345678');

      await tester.enterText(find.byType(TextFormField), '000000');
      await tester.pumpAndSettle();

      expect(find.text('الرمز غير صحيح. تبقّت 4 محاولات.'), findsOneWidget);
      expect(harness.authController.isSignedIn, isFalse);
      expect(find.text('تأكيد'), findsOneWidget);
    },
  );

  testWidgets(
    'an expired code blocks verification until a new one is requested',
    (tester) async {
      final auth = FakeAuthRepository()
        ..verifyError = const ApiException(
          code: 'OTP_EXPIRED',
          statusCode: 400,
        );
      final harness = await pumpApp(tester, harness: TestHarness(auth: auth));
      await openSignIn(tester);
      await enterPhone(tester, '01012345678');

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pumpAndSettle();

      expect(
        find.text('انتهت صلاحية الرمز. اطلب رمزًا جديدًا.'),
        findsOneWidget,
      );
      final verifyButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(verifyButton.onPressed, isNull);
      expect(harness.authController.isSignedIn, isFalse);
    },
  );

  testWidgets('resend is disabled during the countdown and re-arms after it', (
    tester,
  ) async {
    final auth = FakeAuthRepository(resendAfterSeconds: 2);
    final harness = await pumpApp(tester, harness: TestHarness(auth: auth));
    await openSignIn(tester);
    await enterPhone(tester, '01012345678');

    expect(find.textContaining('إعادة الإرسال بعد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('إعادة إرسال الرمز'), findsOneWidget);

    await tester.tap(find.text('إعادة إرسال الرمز'));
    await tester.pumpAndSettle();
    expect(harness.authRepository.requestCount, 2);
    expect(find.text('تم إرسال رمز جديد.'), findsOneWidget);
  });

  testWidgets(
    'shows the development banner only when the backend returns a dev code',
    (tester) async {
      final auth = FakeAuthRepository()..devCode = '424242';
      await pumpApp(tester, harness: TestHarness(auth: auth));
      await openSignIn(tester);
      await enterPhone(tester, '01012345678');
      expect(find.textContaining('وضع التطوير فقط'), findsOneWidget);
      expect(find.textContaining('424242'), findsOneWidget);
    },
  );

  testWidgets('no development banner when the backend sends a real SMS', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSignIn(tester);
    await enterPhone(tester, '01012345678');
    expect(find.textContaining('وضع التطوير فقط'), findsNothing);
  });

  testWidgets('profile shows the role, saves a name and signs out', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await openSignIn(tester);
    await enterPhone(tester, '01012345678');
    await tester.enterText(find.byType(TextFormField), '123456');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle();
    expect(find.text('عميل'), findsOneWidget);
    expect(find.textContaining('01012345678'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'أحمد محمد');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();
    expect(harness.authRepository.lastName, 'أحمد محمد');
    expect(find.text('تم حفظ البيانات.'), findsOneWidget);

    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
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
      expect(
        find.text('أدخل رقم الموبايل وسنرسل إليك رمز تحقق في رسالة نصية.'),
        findsOneWidget,
      );

      await enterPhone(tester, '01012345678');
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.pumpAndSettle();

      // Back on the service detail, now signed in; submission itself lands in Sprint 2.
      expect(harness.authController.isSignedIn, isTrue);
      expect(find.text('تقديم طلبات الخدمة سيتاح قريبًا.'), findsOneWidget);
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
    expect(find.text('Send code'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Send code'))),
      TextDirection.ltr,
    );
  });
}
