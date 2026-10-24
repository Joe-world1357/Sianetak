import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/device/image_picker_service.dart';
import 'package:sianetak_customer/core/device/location_service.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/requests/domain/request_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';

Future<void> openRequestFlow(WidgetTester tester) async {
  await signIn(tester);
  await tester.tap(find.text('سباكة'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('إصلاح تسريب'));
  await tester.pumpAndSettle();
  await tapVisible(tester, find.text('اطلب الخدمة'));
}

Future<void> openRequestsTab(WidgetTester tester) async {
  await tester.tap(find.text('طلباتي').first);
  await tester.pumpAndSettle();
}

Future<void> tapNext(WidgetTester tester) =>
    tapVisible(tester, find.text('التالي'));

Future<void> describe(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'وصف المشكلة'),
    'الحنفية بتسرب مياه من امبارح',
  );
  await tester.pumpAndSettle();
}

Future<void> typeAddress(WidgetTester tester) async {
  await tapVisible(
    tester,
    find.widgetWithText(DropdownButtonFormField<String>, 'المنطقة'),
  );
  await tester.tap(find.text('كيما').last);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'العنوان بالتفصيل'),
    'شارع النيل، عمارة 5',
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('customer completes a request with a photo, location and slot', (
    tester,
  ) async {
    final h = await pumpApp(tester);
    await openRequestFlow(tester);
    expect(find.text('صف المشكلة'), findsOneWidget);

    // Step 1: description is required.
    await tapNext(tester);
    expect(find.text('اكتب وصفًا من 10 أحرف على الأقل.'), findsWidgets);
    await describe(tester);
    await tapVisible(tester, find.text('من المعرض'));
    expect(h.media.uploads, hasLength(1));
    expect(find.bySemanticsLabel(RegExp('صورة 1')), findsOneWidget);
    await tapNext(tester);

    // Step 2: typed address with the current location.
    expect(find.text('عنوان الخدمة'), findsOneWidget);
    await tapNext(tester);
    expect(find.text('اختر المنطقة.'), findsWidgets);
    await typeAddress(tester);
    await tapVisible(tester, find.text('استخدم موقعي الحالي'));
    expect(find.text('تمت إضافة موقعك الحالي إلى العنوان.'), findsOneWidget);
    await tapNext(tester);

    // Step 3: a schedule must be chosen.
    expect(find.text('الموعد'), findsOneWidget);
    await tapNext(tester);
    expect(find.text('اختر موعدًا أو «في أقرب وقت».'), findsWidgets);
    await tapVisible(tester, find.byType(ChoiceChip).at(1));
    await tapNext(tester);

    // Step 4: review shows no invented fee, then submit.
    expect(find.text('مراجعة الطلب'), findsOneWidget);
    expect(find.text('كيما'), findsWidgets);
    await tapVisible(tester, find.text('إرسال الطلب'));

    expect(find.text('تم إرسال طلبك'), findsOneWidget);
    expect(find.textContaining('SN-261024-00001'), findsOneWidget);
    final (submission, key) = h.requests.submissions.single;
    expect(key, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(submission.photoIds, ['media-1']);
    expect(submission.address?.areaId, 'area-kima');
    expect(submission.address?.location, isNotNull);
    expect(submission.schedule.type, ScheduleType.scheduled);

    // The confirmation leads to the request's detail with its initial status.
    await tapVisible(tester, find.text('عرض الطلب'));
    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('بانتظار فني'), findsWidgets);
  });

  testWidgets('a failed photo upload can be retried', (tester) async {
    final media = FakeMediaRepository()
      ..uploadErrors.add(const ApiException(code: 'NETWORK_ERROR'));
    final h = await pumpApp(tester, harness: TestHarness(media: media));
    await openRequestFlow(tester);
    await describe(tester);
    await tapVisible(tester, find.text('التقاط صورة'));
    expect(find.bySemanticsLabel(RegExp('تعذّر رفع الصورة')), findsOneWidget);
    await tapNext(tester);
    expect(find.textContaining('أعد رفع الصور التي فشلت'), findsWidgets);

    await tester.tap(find.byTooltip('إعادة رفع الصورة'));
    await tester.pumpAndSettle();
    expect(h.media.uploads, hasLength(2));
    expect(find.bySemanticsLabel(RegExp('تعذّر رفع الصورة')), findsNothing);
    await tapNext(tester);
    expect(find.text('عنوان الخدمة'), findsOneWidget);
  });

  testWidgets('denied camera access explains how to continue', (tester) async {
    final picker = FakeImagePicker()..next = const ImagePermissionDenied();
    await pumpApp(tester, harness: TestHarness(imagePicker: picker));
    await openRequestFlow(tester);
    await tapVisible(tester, find.text('التقاط صورة'));
    expect(
      find.textContaining('لم يُسمح بالوصول إلى الكاميرا أو الصور'),
      findsOneWidget,
    );
  });

  testWidgets('denied location access falls back to typing the address', (
    tester,
  ) async {
    final location = FakeLocationService()
      ..result = const LocationResult.failed(LocationFailure.denied);
    final h = await pumpApp(tester, harness: TestHarness(location: location));
    await openRequestFlow(tester);
    await describe(tester);
    await tapNext(tester);
    await typeAddress(tester);
    await tapVisible(tester, find.text('استخدم موقعي الحالي'));
    expect(
      find.text('لم يُسمح بالوصول إلى الموقع. اكتب العنوان يدويًا.'),
      findsOneWidget,
    );
    await tapNext(tester);
    await tapVisible(tester, find.text('في أقرب وقت'));
    await tapNext(tester);
    await tapVisible(tester, find.text('إرسال الطلب'));
    expect(find.text('تم إرسال طلبك'), findsOneWidget);
    expect(h.requests.submissions.single.$1.address?.location, isNull);
  });

  testWidgets(
    'a lost response is retried with the same key and creates one request',
    (tester) async {
      final requests = FakeRequestsRepository()
        ..submitErrors.add(const ApiException(code: 'NETWORK_ERROR'));
      final h = await pumpApp(tester, harness: TestHarness(requests: requests));
      await openRequestFlow(tester);
      await describe(tester);
      await tapNext(tester);
      await typeAddress(tester);
      await tapNext(tester);
      await tapVisible(tester, find.text('في أقرب وقت'));
      await tapNext(tester);

      await tapVisible(tester, find.text('إرسال الطلب'));
      expect(find.textContaining('لم يُرسل الطلب'), findsOneWidget);
      expect(find.text('تم إرسال طلبك'), findsNothing);
      await tapVisible(tester, find.text('إرسال الطلب'));
      expect(find.text('تم إرسال طلبك'), findsOneWidget);
      expect(h.requests.submissions, hasLength(2));
      expect(h.requests.submissions[0].$2, h.requests.submissions[1].$2);
      expect(h.requests.created, hasLength(1));
    },
  );

  testWidgets('a saved address is offered first', (tester) async {
    final requests = FakeRequestsRepository(
      addresses: [
        SavedAddress(
          id: 'addr-1',
          label: 'البيت',
          area: sampleArea,
          details: 'شارع السوق، عمارة 3',
        ),
      ],
    );
    final h = await pumpApp(tester, harness: TestHarness(requests: requests));
    await openRequestFlow(tester);
    await describe(tester);
    await tapNext(tester);
    expect(find.textContaining('البيت'), findsOneWidget);
    await tapNext(tester);
    await tapVisible(tester, find.text('في أقرب وقت'));
    await tapNext(tester);
    await tapVisible(tester, find.text('إرسال الطلب'));
    expect(h.requests.submissions.single.$1.addressId, 'addr-1');
  });

  testWidgets('my requests lists submitted requests and opens the detail', (
    tester,
  ) async {
    final requests = FakeRequestsRepository();
    requests.created.add(requestDetail());
    await pumpApp(tester, harness: TestHarness(requests: requests));
    await signIn(tester);
    await openRequestsTab(tester);
    expect(find.textContaining('SN-261024-00001'), findsOneWidget);
    expect(find.text('بانتظار فني'), findsOneWidget);
    await tester.tap(find.textContaining('SN-261024-00001'));
    await tester.pumpAndSettle();
    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.text('الحنفية بتسرب مياه'), findsOneWidget);
    await showVisible(tester, find.text('سجل الطلب'));
    expect(find.text('سجل الطلب'), findsOneWidget);
  });

  testWidgets('my requests shows an empty state', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await openRequestsTab(tester);
    expect(find.text('لم ترسل أي طلب بعد. اختر خدمة لتبدأ.'), findsOneWidget);
  });

  testWidgets('non-customer accounts get their own navigation, not requests', (
    tester,
  ) async {
    final auth = FakeAuthRepository(role: UserRole.admin);
    await pumpApp(tester, harness: TestHarness(auth: auth));
    await signIn(tester);
    expect(find.text('لوحة التشغيل'), findsOneWidget);
    expect(find.text('سباكة'), findsNothing);
    expect(find.text('طلباتي'), findsNothing);
  });

  testWidgets('the request flow works in English and LTR', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await signIn(tester);
    await tester.tap(find.text('Plumbing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leak repair'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Request this service'));
    expect(find.text('Describe the problem'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Describe the problem'))),
      TextDirection.ltr,
    );
  });
}
