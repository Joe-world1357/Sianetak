import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/technician/domain/technician_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';

/// A newly registered technician: the application is their home until it is approved.
TestHarness applicant({
  FakeTechnicianRepository? technician,
  TechnicianStatus status = TechnicianStatus.notSubmitted,
}) => TestHarness(
  auth: FakeAuthRepository(role: UserRole.technician, technicianStatus: status),
  technician: technician,
);

Future<void> openApplication(WidgetTester tester) => signIn(tester);

Future<void> fillForm(WidgetTester tester) async {
  await scrollToTop(tester);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'الاسم الكامل'),
    'محمود علي حسن',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'سنوات الخبرة (اختياري)'),
    '7',
  );
  await tapVisible(tester, find.widgetWithText(FilterChip, 'سباكة'));
  await tapVisible(tester, find.widgetWithText(FilterChip, 'كيما'));
}

void main() {
  testWidgets(
    'a new technician applies with a document and sees the pending status',
    (tester) async {
      final h = await pumpApp(tester, harness: applicant());
      await openApplication(tester);
      expect(find.text('الانضمام كفني'), findsOneWidget);

      // Nothing is sent until the required fields are filled.
      await tapVisible(tester, find.text('إرسال طلب الانضمام'));
      expect(h.technician.submissions, isEmpty);
      expect(find.text('اختر تخصصًا واحدًا على الأقل.'), findsOneWidget);

      await fillForm(tester);
      await tapVisible(tester, find.text('من المعرض'));
      expect(h.media.uploads.single.name, 'technicianDocument');
      await tapVisible(tester, find.text('إرسال طلب الانضمام'));

      final s = h.technician.submissions.single;
      expect(s.fullName, 'محمود علي حسن');
      expect(s.yearsOfExperience, 7);
      expect(s.specialtyCategoryIds, ['cat-plumbing']);
      expect(s.serviceAreaIds, ['area-kima']);
      expect(s.documents.single.$1, 'media-1');
      expect(find.text('قيد المراجعة'), findsOneWidget);
      expect(find.textContaining('يراجع المسؤول بياناتك'), findsOneWidget);
    },
  );

  testWidgets('documents are optional while none are required', (tester) async {
    final h = await pumpApp(tester, harness: applicant());
    await openApplication(tester);
    await fillForm(tester);
    await tapVisible(tester, find.text('إرسال طلب الانضمام'));
    expect(h.technician.submissions.single.documents, isEmpty);
  });

  testWidgets('a configured minimum number of documents is enforced', (
    tester,
  ) async {
    final technician = FakeTechnicianRepository(minDocuments: 1);
    final h = await pumpApp(tester, harness: applicant(technician: technician));
    await openApplication(tester);
    await fillForm(tester);
    await tapVisible(tester, find.text('إرسال طلب الانضمام'));
    expect(h.technician.submissions, isEmpty);
    expect(find.text('أرفق مستندًا واحدًا على الأقل.'), findsWidgets);
  });

  testWidgets('a duplicate application shows the server message', (
    tester,
  ) async {
    final technician = FakeTechnicianRepository()
      ..submitError = const ApiException(
        code: 'APPLICATION_ALREADY_SUBMITTED',
        statusCode: 409,
      );
    await pumpApp(tester, harness: applicant(technician: technician));
    await openApplication(tester);
    await fillForm(tester);
    await tapVisible(tester, find.text('إرسال طلب الانضمام'));
    expect(find.text('الانضمام كفني'), findsOneWidget);
    expect(find.text('طلب الانضمام قيد المراجعة بالفعل.'), findsOneWidget);
  });

  testWidgets('a rejected applicant sees the reason and can resubmit', (
    tester,
  ) async {
    final technician = FakeTechnicianRepository(
      application: technicianApplication(
        status: VerificationStatus.rejected,
        decisionReason: 'صورة البطاقة غير واضحة',
        canResubmit: true,
      ),
    );
    final h = await pumpApp(
      tester,
      harness: applicant(
        technician: technician,
        status: TechnicianStatus.rejected,
      ),
    );
    await openApplication(tester);
    expect(find.text('لم يُقبل'), findsOneWidget);
    expect(find.text('صورة البطاقة غير واضحة'), findsOneWidget);

    await tapVisible(tester, find.text('تعديل وإعادة الإرسال'));
    // The form is prefilled from the rejected application.
    expect(find.text('محمود علي'), findsOneWidget);
    await tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'تعديل وإعادة الإرسال'),
    );
    expect(h.technician.submissions.single.fullName, 'محمود علي');
    expect(h.technician.submissions.single.serviceAreaIds, [sampleArea.id]);
    expect(find.text('قيد المراجعة'), findsOneWidget);
  });

  testWidgets('a suspended technician sees why and cannot take work', (
    tester,
  ) async {
    final technician = FakeTechnicianRepository(
      application: technicianApplication(
        status: VerificationStatus.suspended,
        decisionReason: 'شكاوى متكررة',
      ),
    );
    await pumpApp(
      tester,
      harness: applicant(
        technician: technician,
        status: TechnicianStatus.suspended,
      ),
    );
    await signIn(tester);
    expect(find.text('طلباتي'), findsNothing);
    expect(find.text('العروض'), findsNothing);
    expect(find.text('موقوف'), findsOneWidget);
    expect(find.text('شكاوى متكررة'), findsOneWidget);
    expect(find.text('تعديل وإعادة الإرسال'), findsNothing);
  });

  testWidgets('an approved technician finds the application in the account', (
    tester,
  ) async {
    final technician = FakeTechnicianRepository(
      application: technicianApplication(status: VerificationStatus.approved),
    );
    await pumpApp(
      tester,
      harness: applicant(
        technician: technician,
        status: TechnicianStatus.approved,
      ),
    );
    await signIn(tester);
    await openProfile(tester);
    await tapVisible(tester, find.text('طلب الانضمام كفني'));
    expect(find.text('معتمد'), findsOneWidget);
  });
}
