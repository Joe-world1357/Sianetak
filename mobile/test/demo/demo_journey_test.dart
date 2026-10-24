import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/storage/local_store.dart';
import 'package:sianetak_customer/demo/demo_app.dart';

import '../support/fakes.dart';
import '../support/flows.dart';

/// End-to-end journeys through the real screens and the on-device demo database.
Future<DemoApp> startDemo(WidgetTester tester) async {
  final demo = DemoApp(
    MemoryStorageBackend(),
    imagePicker: FakeImagePicker(),
    location: FakeLocationService(),
  );
  await demo.start();
  await tester.pumpWidget(demo.build());
  await tester.pumpAndSettle();
  return demo;
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

/// From anywhere: back to the root, then sign in as [role] via the account picker.
Future<void> switchTo(WidgetTester tester, String role) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.popUntil((r) => r.isFirst);
  await tester.pumpAndSettle();
  await dismissSnackBars(tester);
  if (find.byIcon(Icons.login).evaluate().isEmpty) {
    await tester.tap(find.text('حسابي').last);
    await tester.pumpAndSettle();
    await tapText(tester, 'تسجيل الخروج');
  }
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
  await tester.tap(find.text(role));
  await tester.pumpAndSettle();
}

Future<void> openRequest(WidgetTester tester, String tab, String ref) async {
  await tester.tap(find.text(tab).last);
  await tester.pumpAndSettle();
  await tapFound(tester, find.textContaining(ref));
}

void main() {
  testWidgets(
    'offer → accept → on the way → quote → approve → complete → rate',
    (tester) async {
      await startDemo(tester);

      // Technician accepts the seeded offer and works the job up to the quote.
      await switchTo(tester, 'فني');
      expect(find.text('عروض العمل'), findsOneWidget);
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
      await switchTo(tester, 'عميل');
      expect(find.text('الرئيسية'), findsOneWidget);
      await openRequest(tester, 'طلباتي', 'SN-DEMO-0002');
      expect(find.textContaining('٣٠٠'), findsWidgets);
      await tapText(tester, 'الموافقة على السعر');
      await scrollUp(tester);
      expect(find.text('العمل جارٍ الآن'), findsOneWidget);

      // Technician finishes and records the cash.
      await switchTo(tester, 'فني');
      await openRequest(tester, 'أعمالي', 'SN-DEMO-0002');
      await tapText(tester, 'تم الانتهاء وتحصيل المبلغ');
      await tapText(tester, 'تأكيد');
      await scrollUp(tester);
      expect(find.text('مكتمل'), findsWidgets);

      // Customer rates the technician.
      await switchTo(tester, 'عميل');
      await openRequest(tester, 'طلباتي', 'SN-DEMO-0002');
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
    'a new request can be assigned by the admin and discussed in chat',
    (tester) async {
      final demo = await startDemo(tester);

      await switchTo(tester, 'عميل');
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
      await tapText(tester, 'التالي'); // Saved address is preselected.
      await tapText(tester, 'التالي');
      await tapText(tester, 'في أقرب وقت');
      await tapText(tester, 'التالي');
      await tapText(tester, 'إرسال الطلب');
      expect(find.text('تم إرسال طلبك'), findsOneWidget);
      final reference =
          (await demo.backend.listRequests())['items'][0]['reference']
              as String;

      // Operations assigns it before any technician answers.
      await switchTo(tester, 'إدارة');
      expect(find.text('لوحة التشغيل'), findsOneWidget);
      await tapFound(tester, find.textContaining(reference));
      await tapText(tester, 'تعيين فني');
      await tapText(tester, 'محمد علي حسن');
      await scrollUp(tester);
      expect(find.text('تم تعيين فني'), findsWidgets);

      // The technician writes to the customer; the customer sees it.
      await switchTo(tester, 'فني');
      await openRequest(tester, 'أعمالي', reference);
      await tapText(tester, 'محادثة الطلب');
      await tester.enterText(find.byType(TextField), 'أنا جاي خلال نص ساعة');
      await tester.tap(find.byTooltip('إرسال'));
      await tester.pumpAndSettle();
      expect(find.text('أنا جاي خلال نص ساعة'), findsOneWidget);

      await switchTo(tester, 'عميل');
      await openRequest(tester, 'طلباتي', reference);
      await tapText(tester, 'محادثة الطلب');
      expect(find.text('أنا جاي خلال نص ساعة'), findsOneWidget);
    },
  );
}
