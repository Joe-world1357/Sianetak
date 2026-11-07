import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/security/password_hasher.dart';
import 'package:sianetak_customer/core/storage/local_store.dart';
import 'package:sianetak_customer/local/local_app.dart';

import '../support/fakes.dart';
import '../support/flows.dart';

/// End-to-end journeys through the real screens and the on-device database, starting from a
/// clean install: every account and record is created in the app, as a user would.
const password = 'secret123';
const adminPhone = '01200000001';
const technicianPhone = '01100000001';
const customerPhone = '01000000001';

Future<LocalApp> startApp(
  WidgetTester tester, [
  StorageBackend? storage,
]) async {
  final app = LocalApp(
    storage ?? MemoryStorageBackend(),
    imagePicker: FakeImagePicker(),
    location: FakeLocationService(),
    hasher: const PasswordHasher(iterations: 1000, background: false),
  );
  await app.start();
  await tester.pumpWidget(app.build());
  await tester.pumpAndSettle();
  return app;
}

/// Taps the last (top-most route's) widget showing [text], scrolling it into view first.
Future<void> tapText(WidgetTester tester, String text) =>
    tapFound(tester, find.text(text));

Future<void> tapFound(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 300, scrollable: _topScrollable());
  }
  await tester.ensureVisible(finder.last);
  await tester.pumpAndSettle();
  await tester.tap(finder.last);
  await tester.pumpAndSettle();
}

/// The scrollable of the route on top (routes underneath stay in the tree, obscured).
Finder _topScrollable() => find.byType(Scrollable).hitTestable().first;

Future<void> scrollUp(WidgetTester tester) async {
  await tester.drag(_topScrollable(), const Offset(0, 5000));
  await tester.pumpAndSettle();
}

/// Fills an account form (name, phone, password, confirmation) and submits it.
Future<void> fillAccount(
  WidgetTester tester,
  String name,
  String phone,
  String button,
) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), name);
  await tester.enterText(fields.at(1), phone);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), password);
  await tapFound(tester, find.widgetWithText(FilledButton, button));
}

/// From anywhere: back to the root, then sign out through the account tab (if signed in).
Future<void> signOut(WidgetTester tester) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.popUntil((r) => r.isFirst);
  await tester.pumpAndSettle();
  await dismissSnackBars(tester);
  if (find.text('حسابي').evaluate().isEmpty) return;
  await tester.tap(find.text('حسابي').last);
  await tester.pumpAndSettle();
  await tapFound(tester, find.widgetWithText(OutlinedButton, 'تسجيل الخروج'));
  await tester.tap(find.widgetWithText(FilledButton, 'تسجيل الخروج'));
  await tester.pumpAndSettle();
}

/// Signs out whoever is signed in, then signs in as [phone] with the password.
Future<void> switchTo(WidgetTester tester, String phone) async {
  await signOut(tester);
  await signIn(tester, phone: phone, password: password);
}

Future<void> openRequest(WidgetTester tester, String tab, String ref) async {
  await tester.tap(find.text(tab).last);
  await tester.pumpAndSettle();
  await tapFound(tester, find.textContaining(ref));
}

/// Clean install → admin setup → technician signs up and applies → admin approves.
Future<LocalApp> onboardTeam(WidgetTester tester) async {
  final app = await startApp(tester);
  expect(find.text('صيانة بيتك في مكان واحد'), findsOneWidget);
  await tester.tap(find.text('تخطي'));
  await tester.pumpAndSettle();

  // The device owner sets up the one administrator.
  await tapFound(tester, find.text('إعداد حساب المسؤول'));
  await fillAccount(tester, 'منى حسن', adminPhone, 'إنشاء حساب المسؤول');
  expect(find.text('لوحة التشغيل'), findsWidgets);

  // Sign out; the setup link is gone now that an administrator exists.
  await signOut(tester);
  expect(find.text('إعداد حساب المسؤول'), findsNothing);

  // A technician signs up and applies.
  await tapText(tester, 'أنشئ حساباً');
  await tapText(tester, 'فني');
  await fillAccount(tester, 'محمد علي', technicianPhone, 'إنشاء الحساب');
  expect(find.text('الانضمام كفني'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'الاسم الكامل'),
    'محمد علي حسن',
  );
  await tapFound(tester, find.widgetWithText(FilterChip, 'سباكة'));
  await tapFound(tester, find.widgetWithText(FilterChip, 'وسط مدينة أسوان'));
  await tapText(tester, 'إرسال طلب الانضمام');
  expect(find.text('قيد المراجعة'), findsOneWidget);
  expect(find.text('العروض'), findsNothing);

  // The administrator approves the application.
  await switchTo(tester, adminPhone);
  await tester.tap(find.text('الفنيون'));
  await tester.pumpAndSettle();
  await tapText(tester, 'محمد علي حسن');
  await tapFound(tester, find.widgetWithText(FilledButton, 'اعتماد'));
  await tester.tap(find.widgetWithText(FilledButton, 'اعتماد').last);
  await tester.pumpAndSettle();
  expect(find.text('معتمد'), findsWidgets);
  return app;
}

/// A customer signs up and submits a leak repair request; returns its reference.
Future<String> customerRequests(WidgetTester tester, LocalApp app) async {
  await signOut(tester);
  await tapText(tester, 'أنشئ حساباً');
  await fillAccount(tester, 'أحمد محمود', customerPhone, 'إنشاء الحساب');
  expect(find.text('طلباتي'), findsOneWidget);
  await tester.tap(find.text('طلباتي'));
  await tester.pumpAndSettle();
  expect(find.text('لم ترسل أي طلب بعد. اختر خدمة لتبدأ.'), findsOneWidget);
  await tester.tap(find.text('الرئيسية'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('سباكة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('إصلاح تسريب مياه'));
  await tester.pumpAndSettle();
  await tapText(tester, 'اطلب الخدمة');
  await tester.enterText(
    find.widgetWithText(TextField, 'وصف المشكلة'),
    'الحنفية بتسرب مياه من امبارح',
  );
  await tester.pumpAndSettle();
  await tapText(tester, 'التالي');
  await tapFound(tester, find.text('المنطقة'));
  await tapText(tester, 'وسط مدينة أسوان');
  await tester.enterText(
    find.widgetWithText(TextField, 'العنوان بالتفصيل'),
    'شارع كورنيش النيل، عمارة ١٢',
  );
  await tester.pumpAndSettle();
  await tapText(tester, 'التالي');
  await tapText(tester, 'في أقرب وقت');
  await tapText(tester, 'التالي');
  await tapText(tester, 'إرسال الطلب');
  expect(find.text('تم إرسال طلبك'), findsOneWidget);
  return (await app.backend.listRequests())['items'][0]['reference'] as String;
}

void main() {
  testWidgets(
    'clean install → accounts → request → offer → quote → complete → rate',
    (tester) async {
      final app = await onboardTeam(tester);
      final reference = await customerRequests(tester, app);

      // The approved technician received the offer, accepts it and works the job.
      await switchTo(tester, technicianPhone);
      expect(find.text('عروض العمل'), findsOneWidget);
      expect(find.textContaining(reference), findsOneWidget);
      await tapText(tester, 'قبول الطلب');
      expect(find.text('تفاصيل الطلب'), findsOneWidget);
      await tapText(tester, 'أنا في الطريق');
      await tapText(tester, 'وصلت');
      await tapText(tester, 'إرسال عرض السعر');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'المبلغ'),
        '300',
      );
      await tapText(tester, 'إرسال عرض السعر');
      await scrollUp(tester);
      expect(find.text('بانتظار موافقة العميل'), findsOneWidget);

      // Customer sees the quote and approves it.
      await switchTo(tester, customerPhone);
      await openRequest(tester, 'طلباتي', reference);
      expect(find.textContaining('٣٠٠'), findsWidgets);
      await tapText(tester, 'الموافقة على السعر');
      await scrollUp(tester);
      expect(find.text('العمل جارٍ الآن'), findsOneWidget);

      // Technician finishes and records the cash.
      await switchTo(tester, technicianPhone);
      await openRequest(tester, 'أعمالي', reference);
      await tapText(tester, 'تم الانتهاء وتحصيل المبلغ');
      await tapText(tester, 'تأكيد');
      await scrollUp(tester);
      expect(find.text('مكتمل'), findsWidgets);

      // Customer rates the technician.
      await switchTo(tester, customerPhone);
      await openRequest(tester, 'طلباتي', reference);
      await tapText(tester, 'قيّم الخدمة');
      await tester.tap(find.byTooltip('5'));
      await tester.pumpAndSettle();
      await tapText(tester, 'إرسال التقييم');
      expect(find.text('شكرًا لتقييمك!'), findsOneWidget);
      await scrollUp(tester);
      expect(find.text('قيّم الخدمة'), findsNothing);
    },
  );

  testWidgets(
    'the admin assigns a request and its participants discuss it in chat',
    (tester) async {
      final app = await onboardTeam(tester);
      final reference = await customerRequests(tester, app);

      // Operations assigns it before the technician answers the offer.
      await switchTo(tester, adminPhone);
      expect(find.text('لوحة التشغيل'), findsOneWidget);
      await tapFound(tester, find.textContaining(reference));
      await tapText(tester, 'تعيين فني');
      await tapText(tester, 'محمد علي حسن');
      await scrollUp(tester);
      expect(find.text('تم تعيين فني'), findsWidgets);

      // The technician writes to the customer; the customer sees it.
      await switchTo(tester, technicianPhone);
      await openRequest(tester, 'أعمالي', reference);
      await tapText(tester, 'محادثة الطلب');
      await tester.enterText(find.byType(TextField), 'أنا جاي خلال نص ساعة');
      await tester.tap(find.byTooltip('إرسال'));
      await tester.pumpAndSettle();
      expect(find.text('أنا جاي خلال نص ساعة'), findsOneWidget);

      await switchTo(tester, customerPhone);
      await openRequest(tester, 'طلباتي', reference);
      await tapText(tester, 'محادثة الطلب');
      expect(find.text('أنا جاي خلال نص ساعة'), findsOneWidget);
    },
  );

  testWidgets('accounts and the session survive an app restart', (
    tester,
  ) async {
    final storage = MemoryStorageBackend();
    await startApp(tester, storage);
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    await tapText(tester, 'أنشئ حساباً');
    await fillAccount(tester, 'أحمد محمود', customerPhone, 'إنشاء الحساب');
    expect(find.text('طلباتي'), findsOneWidget);

    // Relaunch on the same storage: still signed in, no welcome pages.
    await tester.pumpWidget(const SizedBox());
    await startApp(tester, storage);
    expect(find.text('طلباتي'), findsOneWidget);
    expect(find.text('تخطي'), findsNothing);

    // Sign out, relaunch: the sign-in screen, and the password still works.
    await signOut(tester);
    await tester.pumpWidget(const SizedBox());
    await startApp(tester, storage);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await signIn(tester, phone: customerPhone, password: password);
    expect(find.text('طلباتي'), findsOneWidget);
  });
}
