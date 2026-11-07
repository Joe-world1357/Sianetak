import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/device/location_service.dart';
import 'package:sianetak_customer/features/auth/domain/auth_models.dart';
import 'package:sianetak_customer/features/requests/domain/request_models.dart';

import '../support/fakes.dart';
import '../support/flows.dart';
import '../support/pump_app.dart';
import 'request_flow_test.dart' show describe, openRequestFlow, tapNext;

/// Sprint 3 carryover: multi-role accounts, technician availability and the location pin.
void main() {
  AppUser multiRole(UserRole role) => AppUser(
    id: 'u1',
    phone: '+201012345678',
    name: 'محمد',
    role: role,
    roles: const [UserRole.customer, UserRole.technician],
    technicianStatus: role == UserRole.technician
        ? TechnicianStatus.approved
        : null,
  );

  testWidgets('a technician switches to customer mode from the account tab', (
    tester,
  ) async {
    final auth = FakeAuthRepository(role: UserRole.technician)
      ..user = multiRole(UserRole.technician);
    final harness = await pumpApp(tester, harness: TestHarness(auth: auth));
    await signIn(tester);
    expect(find.text('العروض'), findsWidgets);

    await openProfile(tester);
    await tapVisible(tester, find.text('استخدم التطبيق كعميل'));
    expect(auth.switchedTo, [UserRole.customer]);
    expect(harness.authController.user!.role, UserRole.customer);
    // The customer navigation replaces the technician's.
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('طلباتي'), findsOneWidget);

    await openProfile(tester);
    await tapVisible(tester, find.text('التبديل إلى وضع الفني'));
    expect(auth.switchedTo, [UserRole.customer, UserRole.technician]);
    expect(find.text('طلباتي'), findsNothing);
  });

  testWidgets('single-role accounts are not offered a switch', (tester) async {
    await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(role: UserRole.admin)),
    );
    await signIn(tester);
    await openProfile(tester);
    expect(find.text('استخدم التطبيق كعميل'), findsNothing);
    expect(find.text('التبديل إلى وضع الفني'), findsNothing);
  });

  testWidgets('an approved technician turns availability off and on', (
    tester,
  ) async {
    final harness = await pumpApp(
      tester,
      harness: TestHarness(auth: FakeAuthRepository(role: UserRole.technician)),
    );
    await signIn(tester);
    expect(find.text('متاح لاستقبال أعمال جديدة'), findsOneWidget);
    expect(find.text('تصلك العروض الجديدة لتخصصاتك ومناطقك.'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(harness.jobs.available, isFalse);
    expect(
      find.text('لن تصلك عروض أو تكليفات جديدة. أعمالك الحالية لا تتأثر.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(harness.jobs.available, isTrue);
  });

  testWidgets('a request with a pin opens it in the maps app', (tester) async {
    final requests = FakeRequestsRepository();
    requests.created.add(
      requestDetail(coordinates: const GeoPoint(24.0889, 32.8998)),
    );
    final harness = await pumpApp(
      tester,
      harness: TestHarness(requests: requests),
    );
    await signIn(tester);
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('SN-261024-00001'));
    await tester.pumpAndSettle();

    await showVisible(tester, find.text('افتح في الخرائط'));
    expect(find.textContaining('24.08890, 32.89980'), findsOneWidget);
    await tester.tap(find.text('افتح في الخرائط'));
    await tester.pumpAndSettle();
    expect(harness.maps.opened.single.latitude, 24.0889);

    harness.maps.succeeds = false;
    await tester.tap(find.text('افتح في الخرائط'));
    await tester.pumpAndSettle();
    expect(
      find.text('لم يتمكن أي تطبيق خرائط من فتح هذا الموقع.'),
      findsOneWidget,
    );
  });

  testWidgets('the captured pin can be checked and re-captured while '
      'requesting', (tester) async {
    final harness = await pumpApp(tester);
    await openRequestFlow(tester);
    await describe(tester);
    await tapNext(tester);
    await tapVisible(tester, find.text('استخدم موقعي الحالي'));
    await showVisible(tester, find.text('افتح في الخرائط'));
    await tester.tap(find.text('افتح في الخرائط'));
    await tester.pumpAndSettle();
    expect(harness.maps.opened, hasLength(1));

    harness.location.result = const LocationResult.success(
      GeoPoint(24.1, 32.9),
    );
    await tapVisible(tester, find.text('تحديث الموقع'));
    expect(harness.location.calls, 2);
    expect(find.textContaining('24.10000, 32.90000'), findsOneWidget);
  });
}
