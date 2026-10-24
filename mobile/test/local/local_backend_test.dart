import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/core/security/password_hasher.dart';
import 'package:sianetak_customer/core/storage/local_store.dart';
import 'package:sianetak_customer/local/initial_data.dart';
import 'package:sianetak_customer/local/local_backend.dart';

import '../support/fakes.dart';

/// The app's local rules, exercised directly against an in-memory store.
void main() {
  late MemoryStorageBackend storage;
  late DateTime now;
  late LocalBackend backend;

  // Few iterations keep the suite fast; the format and algorithm are the real ones.
  const hasher = PasswordHasher(iterations: 1000, background: false);
  const password = 'secret123';

  LocalBackend open() => LocalBackend(
    LocalStore(storage, seed: buildInitialData, clock: () => now),
    hasher: hasher,
  );

  setUp(() {
    storage = MemoryStorageBackend();
    now = DateTime(2026, 10, 24, 10);
    backend = open();
  });

  Matcher failsWith(String code) =>
      throwsA(isA<ApiException>().having((e) => e.code, 'code', code));

  // Phone numbers of the accounts [world] creates.
  const admin = '01200000001';
  const customer = '01000000001';
  const otherCustomer = '01000000002';
  const technician = '01100000001';
  const karim = '01100000002';
  final ids = <String, String>{};

  Future<void> as(String phone) => backend.signIn(phone, password);

  Future<void> approvedTechnician(
    String phone,
    String name,
    List<String> categories,
    List<String> areas,
  ) async {
    final user = await backend.register(
      name: name,
      phone: phone,
      password: password,
      role: 'technician',
    );
    ids[phone] = user['id'] as String;
    final app = await backend.submitApplication({
      'fullName': name,
      'yearsOfExperience': 5,
      'bio': null,
      'specialtyCategoryIds': [for (final c in categories) 'cat-$c'],
      'serviceAreaIds': [for (final a in areas) 'area-$a'],
      'documents': <dynamic>[],
    });
    await as(admin);
    await backend.decideApplication(
      (app['application'] as Map<String, dynamic>)['id'] as String,
      'approve',
      null,
    );
  }

  /// An administrator, two customers and two approved technicians, all created through the
  /// same calls the screens use. Nothing is pre-seeded.
  Future<void> world() async {
    ids[admin] =
        (await backend.setupAdmin(
              name: 'منى حسن',
              phone: admin,
              password: password,
            ))['id']
            as String;
    for (final (phone, name) in [
      (customer, 'أحمد محمود'),
      (otherCustomer, 'سامي يوسف'),
    ]) {
      ids[phone] =
          (await backend.register(
                name: name,
                phone: phone,
                password: password,
                role: 'customer',
              ))['id']
              as String;
    }
    await approvedTechnician(
      technician,
      'محمد علي حسن',
      [
        'plumbing',
        'electrical',
        'air-conditioning',
        'carpentry',
        'painting',
        'appliances',
      ],
      [
        'aswan-city-centre',
        'el-sahary',
        'kima',
        'el-seil',
        'atlas',
        'west-aswan',
      ],
    );
    await approvedTechnician(
      karim,
      'كريم فؤاد',
      ['plumbing', 'painting'],
      ['aswan-city-centre', 'el-sahary'],
    );
    await backend.signOut();
  }

  Future<String> submit({
    String serviceId = 'svc-plumbing-leak-repair',
    String areaId = 'area-aswan-city-centre',
  }) async {
    await as(customer);
    final detail = await backend.submitRequest({
      'serviceId': serviceId,
      'description': 'الحوض بيسرب مياه من امبارح',
      'address': {'areaId': areaId, 'details': 'شارع النيل ٥'},
      'schedule': {'type': 'asap'},
    }, 'key-$serviceId-$areaId');
    return detail['id'] as String;
  }

  Future<String> offerFor(String requestId, String phone) async {
    await as(phone);
    final offers = await backend.offers();
    return (offers.firstWhere((o) => o['id'] == requestId)['offer']
            as Map<String, dynamic>)['id']
        as String;
  }

  group('a fresh database', () {
    test('holds the catalog and nothing else', () async {
      expect(await backend.categories(), hasLength(6));
      expect(await backend.areas(), hasLength(6));
      expect(await backend.hasAdmin(), isFalse);
      expect(await backend.onboardingSeen(), isFalse);
      expect(await backend.currentUser(), isNull);
      for (final table in [
        'users',
        'requests',
        'applications',
        'offers',
        'messages',
        'notifications',
        'addresses',
      ]) {
        expect(backend.store.table(table), isEmpty, reason: table);
      }
    });

    test('replaces an older demo database but keeps a backup of it', () async {
      final old = jsonEncode({
        'version': 3,
        'users': [
          {'id': 'u-customer', 'phone': '+201001234567'},
        ],
      });
      storage.document = old;
      final reopened = open();
      expect(await reopened.hasAdmin(), isFalse);
      expect(reopened.store.table('users'), isEmpty);
      expect(storage.backups, [old]);
    });

    test(
      'keeps an unreadable file as a backup instead of deleting it',
      () async {
        storage.document = '{not json';
        final reopened = open();
        expect(await reopened.categories(), hasLength(6));
        expect(storage.backups, ['{not json']);
      },
    );
  });

  group('accounts', () {
    test('registering stores a salted hash, never the password', () async {
      final user = await backend.register(
        name: '  أحمد محمود ',
        phone: '٠١٠٠٠٠٠٠٠٠١',
        password: password,
        role: 'customer',
      );
      expect(user['phone'], '+201000000001');
      expect(user['name'], 'أحمد محمود');
      final row = backend.store.table('users').single;
      final hash = row['passwordHash'] as String;
      expect(hash, startsWith('pbkdf2-sha256\$1000\$'));
      expect(
        jsonEncode(backend.store.table('users')),
        isNot(contains(password)),
      );
      expect(await hasher.verify(password, hash), isTrue);
      expect(await hasher.verify('secret124', hash), isFalse);
      // Signed straight in.
      expect((await backend.currentUser())!['role'], 'customer');
    });

    test(
      'rejects duplicates, weak passwords, bad numbers and admin sign-up',
      () async {
        await backend.register(
          name: 'أحمد',
          phone: customer,
          password: password,
          role: 'customer',
        );
        await expectLater(
          backend.register(
            name: 'آخر',
            phone: '+20 100 000 0001',
            password: password,
            role: 'technician',
          ),
          failsWith('PHONE_TAKEN'),
        );
        for (final weak in ['short1', 'onlyletters', '12345678']) {
          await expectLater(
            backend.register(
              name: 'سامي',
              phone: otherCustomer,
              password: weak,
              role: 'customer',
            ),
            failsWith('WEAK_PASSWORD'),
          );
        }
        await expectLater(
          backend.register(
            name: 'سامي',
            phone: '0123',
            password: password,
            role: 'customer',
          ),
          failsWith('INVALID_PHONE'),
        );
        await expectLater(
          backend.register(
            name: 'سامي',
            phone: otherCustomer,
            password: password,
            role: 'admin',
          ),
          failsWith('FORBIDDEN'),
        );
        expect(backend.store.table('users'), hasLength(1));
      },
    );

    test(
      'sign-in checks the password and locks out repeated failures',
      () async {
        await backend.register(
          name: 'أحمد',
          phone: customer,
          password: password,
          role: 'customer',
        );
        await backend.signOut();
        await expectLater(
          backend.signIn('01099999999', password),
          failsWith('INVALID_CREDENTIALS'),
        );
        for (var i = 0; i < AppRules.maxFailedSignIns; i++) {
          await expectLater(
            backend.signIn(customer, 'wrong-pass1'),
            failsWith('INVALID_CREDENTIALS'),
          );
        }
        // Locked, even with the right password.
        await expectLater(
          backend.signIn(customer, password),
          failsWith('TOO_MANY_ATTEMPTS'),
        );
        now = now.add(const Duration(minutes: AppRules.signInLockMinutes + 1));
        final user = await backend.signIn(customer, password);
        expect(user['phone'], '+201000000001');
      },
    );

    test(
      'a session survives a restart, expires, and ends on sign-out',
      () async {
        await backend.register(
          name: 'أحمد',
          phone: customer,
          password: password,
          role: 'customer',
        );
        var reopened = open();
        expect((await reopened.currentUser(renew: true))!['name'], 'أحمد');

        now = now.add(LocalStore.sessionLifetime + const Duration(days: 1));
        reopened = open();
        expect(await reopened.currentUser(renew: true), isNull);
        await expectLater(
          reopened.listRequests(),
          failsWith('UNAUTHENTICATED'),
        );

        await reopened.signIn(customer, password);
        await reopened.signOut();
        expect(await open().currentUser(), isNull);
      },
    );

    test('changing the password needs the current one', () async {
      await backend.register(
        name: 'أحمد',
        phone: customer,
        password: password,
        role: 'customer',
      );
      await expectLater(
        backend.changePassword('wrong-pass1', 'newpass99'),
        failsWith('WRONG_PASSWORD'),
      );
      await backend.changePassword(password, 'newpass99');
      await backend.signOut();
      await expectLater(
        backend.signIn(customer, password),
        failsWith('INVALID_CREDENTIALS'),
      );
      await backend.signIn(customer, 'newpass99');
    });

    test(
      'the first administrator is set up once; then only admins add admins',
      () async {
        await backend.setupAdmin(name: 'منى', phone: admin, password: password);
        expect(await backend.hasAdmin(), isTrue);
        await backend.signOut();
        await expectLater(
          backend.setupAdmin(
            name: 'دخيل',
            phone: otherCustomer,
            password: password,
          ),
          failsWith('ADMIN_EXISTS'),
        );
        await backend.register(
          name: 'أحمد',
          phone: customer,
          password: password,
          role: 'customer',
        );
        await expectLater(
          backend.createAdmin(
            name: 'دخيل',
            phone: otherCustomer,
            password: password,
          ),
          failsWith('FORBIDDEN'),
        );
        await as(admin);
        final second = await backend.createAdmin(
          name: 'خالد',
          phone: otherCustomer,
          password: password,
        );
        expect(second['role'], 'admin');
        // The creating admin stays signed in.
        expect((await backend.currentUser())!['phone'], '+201200000001');
      },
    );

    test('onboarding is remembered across restarts', () async {
      await backend.markOnboardingSeen();
      expect(await open().onboardingSeen(), isTrue);
    });
  });

  group('workflows', () {
    setUp(world);

    test('data survives a restart', () async {
      final id = await submit();
      final reopened = open();
      expect((await reopened.currentUser())!['id'], ids[customer]);
      expect((await reopened.getRequest(id))['status'], 'submitted');
    });

    test(
      'a retried submission with the same key creates one request',
      () async {
        await submit();
        await submit();
        final page = await backend.listRequests();
        expect(page['items'], hasLength(1));
      },
    );

    test(
      'technicians take no work until approved, and none once suspended',
      () async {
        final user = await backend.register(
          name: 'خالد عبد الرحمن',
          phone: '01100000009',
          password: password,
          role: 'technician',
        );
        expect(user['technicianStatus'], 'not_submitted');
        await expectLater(
          backend.offers(),
          failsWith('TECHNICIAN_NOT_APPROVED'),
        );
        final app = await backend.submitApplication({
          'fullName': 'خالد عبد الرحمن',
          'yearsOfExperience': 6,
          'bio': null,
          'specialtyCategoryIds': ['cat-air-conditioning'],
          'serviceAreaIds': ['area-atlas'],
          'documents': <dynamic>[],
        });
        expect(
          (await backend.currentUser())!['technicianStatus'],
          'pending_review',
        );
        await expectLater(
          backend.jobs(active: true),
          failsWith('TECHNICIAN_NOT_APPROVED'),
        );

        final appId =
            (app['application'] as Map<String, dynamic>)['id'] as String;
        await as(admin);
        await expectLater(
          backend.decideApplication(appId, 'reject', ' '),
          failsWith('VALIDATION_FAILED'),
        );
        await backend.decideApplication(appId, 'approve', null);
        await as('01100000009');
        expect((await backend.currentUser())!['technicianStatus'], 'approved');
        expect(await backend.offers(), isEmpty);

        await as(admin);
        await backend.decideApplication(appId, 'suspend', 'شكاوى متكررة');
        await as('01100000009');
        await expectLater(
          backend.offers(),
          failsWith('TECHNICIAN_NOT_APPROVED'),
        );
      },
    );

    test(
      'offers go only to approved technicians covering the category and area',
      () async {
        final id = await submit(
          serviceId: 'svc-plumbing-leak-repair',
          areaId: 'area-el-sahary',
        );
        await as(technician);
        expect([for (final o in await backend.offers()) o['id']], contains(id));
        await as(karim);
        expect([for (final o in await backend.offers()) o['id']], contains(id));

        // Karim does not cover Kima or electrical work.
        final other = await submit(
          serviceId: 'svc-electrical-fault-diagnosis',
          areaId: 'area-kima',
        );
        await as(karim);
        expect([
          for (final o in await backend.offers()) o['id'],
        ], isNot(contains(other)));
      },
    );

    test('only the first technician to accept secures the request', () async {
      final id = await submit();
      final mine = await offerFor(id, technician);
      final karims = await offerFor(id, karim);

      await as(technician);
      final accepted = await backend.respondToOffer(mine, accept: true);
      expect(accepted['status'], 'assigned');

      await as(karim);
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
        now = now.add(const Duration(minutes: AppRules.offerMinutes + 1));
        await as(admin);
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
        ], contains(ids[technician]));
        final assigned = await backend.assign(id, ids[technician]!);
        expect(assigned['status'], 'assigned');
      },
    );

    test('a declined offer by everyone leaves the request unmatched', () async {
      final id = await submit();
      for (final tech in [technician, karim]) {
        final offer = await offerFor(id, tech);
        await backend.respondToOffer(offer, accept: false);
      }
      await as(customer);
      expect((await backend.getRequest(id))['status'], 'unmatched');
    });

    test('work cannot start before the customer approves the quote', () async {
      final id = await submit();
      final offer = await offerFor(id, technician);
      await backend.respondToOffer(offer, accept: true);
      await backend.advanceJob(id, 'en_route');
      await backend.advanceJob(id, 'arrived');
      await backend.sendQuote(id, 30000, 'تغيير وصلة');
      await expectLater(
        backend.advanceJob(id, 'completed'),
        failsWith('REQUEST_STATE_CONFLICT'),
      );

      // Declined, then re-quoted and approved.
      await as(customer);
      await backend.decideQuote(id, approve: false);
      await as(technician);
      await backend.sendQuote(id, 25000, null);
      await as(customer);
      expect(
        (await backend.decideQuote(id, approve: true))['status'],
        'in_progress',
      );

      await as(technician);
      final done = await backend.advanceJob(id, 'completed');
      expect(done['payment'], {
        'amountMinor': 25000,
        'commissionMinor': 2500,
        'at': isA<String>(),
      });

      await as(customer);
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
      final offer = await offerFor(id, technician);
      // Before accepting, an offered technician sees the area but not the address.
      await as(technician);
      final preview = await backend.getRequest(id);
      expect((preview['location'] as Map<String, dynamic>)['details'], '');
      await expectLater(backend.sendMessage(id, 'hi'), failsWith('FORBIDDEN'));

      await backend.respondToOffer(offer, accept: true);
      await backend.sendMessage(id, 'أنا في الطريق');
      await as(customer);
      final messages = await backend.messages(id);
      expect(messages.single['text'], 'أنا في الطريق');
      expect(messages.single['mine'], isFalse);

      await as(karim);
      await expectLater(backend.messages(id), failsWith('REQUEST_NOT_FOUND'));
      await as(otherCustomer);
      await expectLater(backend.getRequest(id), failsWith('REQUEST_NOT_FOUND'));
    });

    test('uploads accept real images only and stay private', () async {
      await as(customer);
      await expectLater(
        backend.uploadMedia('request_photo', Uint8List.fromList([1, 2, 3])),
        failsWith('UNSUPPORTED_FILE_TYPE'),
      );
      final media = await backend.uploadMedia('request_photo', transparentPng);
      expect(media['contentType'], 'image/png');
      expect(await backend.mediaContent(media['id'] as String), transparentPng);
      await as(otherCustomer);
      await expectLater(
        backend.mediaContent(media['id'] as String),
        failsWith('MEDIA_NOT_FOUND'),
      );
    });

    test('role checks mirror the server', () async {
      await as(customer);
      await expectLater(backend.offers(), failsWith('FORBIDDEN'));
      await expectLater(
        backend.createAdmin(
          name: 'x',
          phone: '01000000009',
          password: password,
        ),
        failsWith('FORBIDDEN'),
      );
      await expectLater(backend.adminOverview(), failsWith('FORBIDDEN'));
      await backend.signOut();
      await expectLater(backend.listRequests(), failsWith('UNAUTHENTICATED'));
    });
  });
}
