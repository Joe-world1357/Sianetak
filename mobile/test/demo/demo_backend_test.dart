import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/core/storage/local_store.dart';
import 'package:sianetak_customer/demo/demo_backend.dart';
import 'package:sianetak_customer/demo/demo_seed.dart';

import '../support/fakes.dart';

/// The demo's local rules, exercised directly against an in-memory store.
void main() {
  late MemoryStorageBackend storage;
  late DateTime now;
  late DemoBackend backend;

  DemoBackend open() =>
      DemoBackend(LocalStore(storage, seed: buildDemoSeed, clock: () => now));

  setUp(() {
    storage = MemoryStorageBackend();
    now = DateTime(2026, 10, 24, 10);
    backend = open();
  });

  Matcher failsWith(String code) =>
      throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

  Future<String> submit({
    String serviceId = 'svc-plumbing-leak-repair',
    String areaId = 'area-aswan-city-centre',
  }) async {
    await backend.signIn(DemoIds.customer);
    final detail = await backend.submitRequest({
      'serviceId': serviceId,
      'description': 'الحوض بيسرب مياه من امبارح',
      'address': {'areaId': areaId, 'details': 'شارع النيل ٥'},
      'schedule': {'type': 'asap'},
    }, 'key-$serviceId-$areaId');
    return detail['id'] as String;
  }

  Future<String> offerFor(String requestId, String technicianId) async {
    await backend.signIn(technicianId);
    final offers = await backend.offers();
    return (offers.firstWhere((o) => o['id'] == requestId)['offer']
            as Map<String, dynamic>)['id']
        as String;
  }

  test('seeds three demo accounts and the sample catalog', () async {
    final accounts = await backend.demoAccounts();
    expect(
      [for (final a in accounts) a['role']],
      ['customer', 'technician', 'admin'],
    );
    expect(await backend.categories(), hasLength(6));
    expect(await backend.currentUser(), isNull);
  });

  test(
    'data and the signed-in account survive a restart; reset restores the seed',
    () async {
      final id = await submit();
      final reopened = open();
      expect((await reopened.currentUser())!['id'], DemoIds.customer);
      expect((await reopened.getRequest(id))['status'], 'submitted');

      await reopened.store.reset();
      expect(await reopened.currentUser(), isNull);
      await reopened.signIn(DemoIds.customer);
      final page = await reopened.listRequests();
      expect(page['items'], hasLength(2)); // Only the seeded requests remain.
    },
  );

  test('a retried submission with the same key creates one request', () async {
    await submit();
    await submit();
    final page = await backend.listRequests();
    expect(page['items'], hasLength(3));
  });

  test(
    'offers go only to approved technicians covering the category and area',
    () async {
      final id = await submit(
        serviceId: 'svc-plumbing-leak-repair',
        areaId: 'area-el-sahary',
      );
      await backend.signIn(DemoIds.technician);
      expect([for (final o in await backend.offers()) o['id']], contains(id));
      await backend.signIn('u-karim');
      expect([for (final o in await backend.offers()) o['id']], contains(id));

      // Karim does not cover Kima or electrical work.
      final other = await submit(
        serviceId: 'svc-electrical-fault-diagnosis',
        areaId: 'area-kima',
      );
      await backend.signIn('u-karim');
      expect([
        for (final o in await backend.offers()) o['id'],
      ], isNot(contains(other)));
    },
  );

  test('only the first technician to accept secures the request', () async {
    final id = await submit();
    final mine = await offerFor(id, DemoIds.technician);
    final karims = await offerFor(id, 'u-karim');

    await backend.signIn(DemoIds.technician);
    final accepted = await backend.respondToOffer(mine, accept: true);
    expect(accepted['status'], 'assigned');

    await backend.signIn('u-karim');
    await expectLater(
      backend.respondToOffer(karims, accept: true),
      failsWith('OFFER_TAKEN'),
    );
    // And Karim can no longer read the request.
    await expectLater(backend.getRequest(id), failsWith('REQUEST_NOT_FOUND'));
  });

  test(
    'expired offers fall back to operations, who can assign manually',
    () async {
      final id = await submit();
      now = now.add(const Duration(minutes: DemoRules.offerMinutes + 1));
      await backend.signIn(DemoIds.admin);
      expect((await backend.getRequest(id))['status'], 'unmatched');
      final notices = await backend.notifications();
      expect(
        notices.any(
          (n) => n['type'] == 'request_unmatched' && n['requestId'] == id,
        ),
        isTrue,
      );

      final technicians = await backend.assignableTechnicians(id);
      expect([
        for (final t in technicians) t['id'],
      ], contains(DemoIds.technician));
      final assigned = await backend.assign(id, DemoIds.technician);
      expect(assigned['status'], 'assigned');
    },
  );

  test('a declined offer by everyone leaves the request unmatched', () async {
    final id = await submit();
    for (final tech in [DemoIds.technician, 'u-karim']) {
      final offer = await offerFor(id, tech);
      await backend.respondToOffer(offer, accept: false);
    }
    await backend.signIn(DemoIds.customer);
    expect((await backend.getRequest(id))['status'], 'unmatched');
  });

  test('work cannot start before the customer approves the quote', () async {
    final id = await submit();
    final offer = await offerFor(id, DemoIds.technician);
    await backend.respondToOffer(offer, accept: true);
    await backend.advanceJob(id, 'en_route');
    await backend.advanceJob(id, 'arrived');
    await backend.sendQuote(id, 30000, 'تغيير وصلة');
    await expectLater(
      backend.advanceJob(id, 'completed'),
      failsWith('REQUEST_STATE_CONFLICT'),
    );

    // Declined, then re-quoted and approved.
    await backend.signIn(DemoIds.customer);
    await backend.decideQuote(id, approve: false);
    await backend.signIn(DemoIds.technician);
    await backend.sendQuote(id, 25000, null);
    await backend.signIn(DemoIds.customer);
    expect(
      (await backend.decideQuote(id, approve: true))['status'],
      'in_progress',
    );

    await backend.signIn(DemoIds.technician);
    final done = await backend.advanceJob(id, 'completed');
    expect(done['payment'], {
      'amountMinor': 25000,
      'commissionMinor': 2500,
      'at': isA<String>(),
    });

    await backend.signIn(DemoIds.customer);
    await expectLater(
      backend.cancelRequest(id, 'x'),
      failsWith('REQUEST_STATE_CONFLICT'),
    );
    final rated = await backend.rate(id, 4, 'كويس');
    expect((rated['rating'] as Map<String, dynamic>)['stars'], 4);
    await expectLater(
      backend.rate(id, 5, null),
      failsWith('REQUEST_STATE_CONFLICT'),
    );

    final timeline = [
      for (final e in rated['timeline'] as List<dynamic>)
        (e as Map<String, dynamic>)['status'],
    ];
    expect(timeline, [
      'submitted',
      'assigned',
      'en_route',
      'arrived',
      'quoted',
      'quote_rejected',
      'quoted',
      'in_progress',
      'completed',
    ]);
  });

  test('requests and chats are private to their participants', () async {
    final id = await submit();
    final offer = await offerFor(id, DemoIds.technician);
    // Before accepting, an offered technician sees the area but not the address.
    await backend.signIn(DemoIds.technician);
    final preview = await backend.getRequest(id);
    expect((preview['location'] as Map<String, dynamic>)['details'], '');
    await expectLater(backend.sendMessage(id, 'hi'), failsWith('FORBIDDEN'));

    await backend.respondToOffer(offer, accept: true);
    await backend.sendMessage(id, 'أنا في الطريق');
    await backend.signIn(DemoIds.customer);
    final messages = await backend.messages(id);
    expect(messages.single['text'], 'أنا في الطريق');
    expect(messages.single['mine'], isFalse);

    await backend.signIn('u-karim');
    await expectLater(backend.messages(id), failsWith('REQUEST_NOT_FOUND'));
    await backend.signIn('u-sami');
    await expectLater(backend.getRequest(id), failsWith('REQUEST_NOT_FOUND'));
  });

  test(
    'approving an application turns the applicant into a technician',
    () async {
      await backend.signIn(DemoIds.admin);
      final pending = await backend.listApplications('pending_review');
      expect(pending, hasLength(2));
      expect(
        () => backend.decideApplication('app-sami', 'reject', ' '),
        failsWith('VALIDATION_FAILED'),
      );
      await backend.decideApplication('app-sami', 'approve', null);
      await backend.signIn('u-sami');
      expect((await backend.currentUser())!['role'], 'technician');
    },
  );

  test('uploads accept real images only and stay private', () async {
    await backend.signIn(DemoIds.customer);
    await expectLater(
      backend.uploadMedia('request_photo', Uint8List.fromList([1, 2, 3])),
      failsWith('UNSUPPORTED_FILE_TYPE'),
    );
    final media = await backend.uploadMedia('request_photo', transparentPng);
    expect(media['contentType'], 'image/png');
    expect(await backend.mediaContent(media['id'] as String), transparentPng);
    await backend.signIn('u-sami');
    await expectLater(
      backend.mediaContent(media['id'] as String),
      failsWith('MEDIA_NOT_FOUND'),
    );
  });

  test('role checks mirror the server', () async {
    await backend.signIn(DemoIds.customer);
    await expectLater(backend.offers(), failsWith('FORBIDDEN'));
    await expectLater(backend.adminOverview(), failsWith('FORBIDDEN'));
    await backend.signOut();
    await expectLater(backend.listRequests(), failsWith('UNAUTHENTICATED'));
  });
}
