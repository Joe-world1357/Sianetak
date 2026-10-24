import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/admin/data/admin_repository.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/technician/domain/technician_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';

FakeAuthRepository adminAuth() => FakeAuthRepository()
  ..user = const AppUser(
    id: 'admin-1',
    phone: '+201011111111',
    name: 'مشرف',
    role: UserRole.admin,
  );

Future<TestHarness> openQueue(
  WidgetTester tester,
  FakeAdminRepository admin,
) async {
  final h = await pumpApp(
    tester,
    harness: TestHarness(auth: adminAuth(), admin: admin),
  );
  await signIn(tester);
  await tester.tap(find.text('الفنيون'));
  await tester.pumpAndSettle();
  return h;
}

void main() {
  testWidgets('admin opens a pending application and approves it', (
    tester,
  ) async {
    final admin = FakeAdminRepository([reviewApplication()]);
    await openQueue(tester, admin);
    expect(find.text('طلبات الفنيين'), findsOneWidget);
    expect(find.text('محمود علي'), findsOneWidget);

    await tester.tap(find.text('محمود علي'));
    await tester.pumpAndSettle();
    expect(find.textContaining('01098765432'), findsOneWidget);
    await showVisible(
      tester,
      find.text('ملف PDF (المعاينة غير متاحة في التطبيق)'),
    );
    expect(
      find.text('ملف PDF (المعاينة غير متاحة في التطبيق)'),
      findsOneWidget,
    );
    expect(find.text('سجل المراجعة'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'اعتماد'));
    expect(find.text('اعتماد الفني؟'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'اعتماد').last);
    await tester.pumpAndSettle();

    expect(admin.decisions.single, ('app-1', ReviewAction.approve, null));
    expect(find.text('تم حفظ القرار.'), findsOneWidget);
    expect(find.text('معتمد'), findsWidgets);
    await showVisible(tester, find.text('إيقاف'));
    expect(find.text('إيقاف'), findsOneWidget);

    // Back on the queue the approved application has left the pending list.
    await tester.tap(find.byTooltip('رجوع').last);
    await tester.pumpAndSettle();
    expect(find.text('لا توجد طلبات بهذه الحالة.'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'معتمد'));
    await tester.pumpAndSettle();
    expect(find.text('محمود علي'), findsOneWidget);
  });

  testWidgets('rejecting requires a reason that is sent to the server', (
    tester,
  ) async {
    final admin = FakeAdminRepository([reviewApplication()]);
    await openQueue(tester, admin);
    await tester.tap(find.text('محمود علي'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'رفض'));
    await tester.tap(find.widgetWithText(FilledButton, 'رفض'));
    await tester.pumpAndSettle();
    expect(find.text('اكتب سببًا من 3 أحرف على الأقل.'), findsOneWidget);
    expect(admin.decisions, isEmpty);

    await tester.enterText(
      find.byType(TextFormField),
      'صورة البطاقة غير واضحة',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'رفض'));
    await tester.pumpAndSettle();
    expect(admin.decisions.single, (
      'app-1',
      ReviewAction.reject,
      'صورة البطاقة غير واضحة',
    ));
    expect(find.text('لم يُقبل'), findsWidgets);
    expect(find.text('صورة البطاقة غير واضحة'), findsWidgets);
  });

  testWidgets('cancelling a decision sends nothing', (tester) async {
    final admin = FakeAdminRepository([reviewApplication()]);
    await openQueue(tester, admin);
    await tester.tap(find.text('محمود علي'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'رفض'));
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(admin.decisions, isEmpty);
  });

  testWidgets('a suspended technician can be reinstated', (tester) async {
    final admin = FakeAdminRepository([
      reviewApplication(status: VerificationStatus.suspended),
    ]);
    await openQueue(tester, admin);
    await tester.tap(find.widgetWithText(ChoiceChip, 'موقوف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محمود علي'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('إعادة التفعيل'));
    await tester.tap(find.widgetWithText(FilledButton, 'اعتماد'));
    await tester.pumpAndSettle();
    expect(admin.decisions.single.$2, ReviewAction.approve);
    expect(find.text('معتمد'), findsWidgets);
  });

  testWidgets('a conflicting decision shows the server message and reloads', (
    tester,
  ) async {
    final admin = FakeAdminRepository([reviewApplication()])
      ..decideError = const ApiException(
        code: 'APPLICATION_STATE_CONFLICT',
        statusCode: 409,
      );
    await openQueue(tester, admin);
    await tester.tap(find.text('محمود علي'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'اعتماد'));
    await tester.tap(find.widgetWithText(FilledButton, 'اعتماد').last);
    await tester.pumpAndSettle();
    expect(find.text('تم حفظ القرار.'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('customers do not see the admin navigation', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    expect(find.text('الفنيون'), findsNothing);
    expect(find.text('لوحة التحكم'), findsNothing);
  });

  testWidgets('the admin queue works in English', (tester) async {
    final admin = FakeAdminRepository([reviewApplication()]);
    final h = await openQueue(tester, admin);
    h.locale.toggle();
    await tester.pumpAndSettle();
    expect(find.text('Technician applications'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Technician applications'))),
      TextDirection.ltr,
    );
  });
}
