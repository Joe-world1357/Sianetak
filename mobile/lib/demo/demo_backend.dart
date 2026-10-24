import 'dart:math';
import 'dart:typed_data';

import '../core/network/api_exception.dart';
import '../core/storage/local_store.dart';
import 'demo_seed.dart';

/// The rules the NestJS API used to enforce, re-implemented over [LocalStore] so the app runs
/// standalone. Every method answers in the API's JSON shape, so the existing models parse it
/// unchanged, and failures use the API's error codes, so the existing error copy applies.
class DemoBackend {
  DemoBackend(this.store, {Random? random}) : _random = random ?? Random();

  final LocalStore store;
  final Random _random;

  DateTime get _now => store.now();
  String _iso(DateTime t) => t.toUtc().toIso8601String();
  DateTime _date(Object? iso) => DateTime.parse(iso! as String);

  Never _fail(String code, [int status = 400, Map<String, dynamic>? details]) =>
      throw ApiException(
        code: code,
        statusCode: status,
        details: details ?? const {},
      );

  // ---------------------------------------------------------------------------------------
  // Accounts

  static const demoAccountIds = [
    DemoIds.customer,
    DemoIds.technician,
    DemoIds.admin,
  ];

  Future<List<Row>> demoAccounts() async {
    await store.open();
    return [
      for (final id in demoAccountIds)
        if (store.find('users', id) case final u?) _user(u),
    ];
  }

  Row _user(Row u) => {
    'id': u['id'],
    'phone': u['phone'],
    'name': u['name'],
    'role': u['role'],
  };

  Future<Row?> currentUser() async {
    await store.open();
    final u = store.sessionUser;
    return u == null ? null : _user(u);
  }

  Future<Row> signIn(String userId) => store.write(() {
    final u = store.require('users', userId, 'NOT_FOUND');
    store.setSession(userId);
    return _user(u);
  });

  Future<void> signOut() => store.write(() => store.setSession(null));

  Future<Row> updateName(String name) => store.write(() {
    final u = store.requireUser();
    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 80) _fail('VALIDATION_FAILED');
    u['name'] = trimmed;
    return _user(u);
  });

  // ---------------------------------------------------------------------------------------
  // Catalog

  Row _category(Row c, {bool withCount = true}) => {
    'id': c['id'],
    'slug': c['slug'],
    'name': c['name'],
    'description': c['description'],
    'iconKey': c['iconKey'],
    'isSample': c['isSample'] ?? false,
    if (withCount)
      'serviceCount': store
          .table('services')
          .where((s) => s['categoryId'] == c['id'])
          .length,
  };

  Row _serviceSummary(Row s) => {
    'id': s['id'],
    'slug': s['slug'],
    'name': s['name'],
    'pricing': s['pricing'],
    'isSample': s['isSample'] ?? false,
  };

  Row? _bySlug(String table, String slug) {
    for (final row in store.table(table)) {
      if (row['slug'] == slug) return row;
    }
    return null;
  }

  Future<List<Row>> categories() async {
    await store.open();
    final rows = [
      ...store.table('categories'),
    ]..sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int));
    return [for (final c in rows) _category(c)];
  }

  Future<Row> category(String slug) async {
    await store.open();
    final c = _bySlug('categories', slug) ?? _fail('CATEGORY_NOT_FOUND', 404);
    return {
      ..._category(c),
      'services': [
        for (final s in store.table('services'))
          if (s['categoryId'] == c['id']) _serviceSummary(s),
      ],
    };
  }

  Future<Row> service(String slug) async {
    await store.open();
    final s = _bySlug('services', slug) ?? _fail('SERVICE_NOT_FOUND', 404);
    final c = store.find('categories', s['categoryId'] as String)!;
    return {
      ..._serviceSummary(s),
      'description': s['description'],
      'category': {'slug': c['slug'], 'name': c['name']},
    };
  }

  // ---------------------------------------------------------------------------------------
  // Areas, options and addresses

  Row _area(String id) {
    final a = store.require('areas', id, 'AREA_NOT_AVAILABLE');
    return {
      'id': a['id'],
      'slug': a['slug'],
      'name': a['name'],
      'isSample': a['isSample'] ?? false,
    };
  }

  Future<List<Row>> areas() async {
    await store.open();
    return [for (final a in store.table('areas')) _area(a['id'] as String)];
  }

  /// Bookable local windows from today through [DemoRules.scheduleDaysAhead], after the lead.
  List<(DateTime, DateTime)> _slots() {
    final now = _now;
    final earliest = now.add(
      const Duration(minutes: DemoRules.scheduleLeadMinutes),
    );
    return [
      for (var d = 0; d <= DemoRules.scheduleDaysAhead; d++)
        for (final (from, to) in DemoRules.slotWindows)
          if (DateTime(now.year, now.month, now.day + d, 0, from)
              case final start when !start.isBefore(earliest))
            (start, DateTime(now.year, now.month, now.day + d, 0, to)),
    ];
  }

  Future<Row> requestOptions() async {
    await store.open();
    return {
      'description': {'minLength': 10, 'maxLength': 1000},
      'photos': {
        'max': DemoRules.maxPhotos,
        'maxBytes': DemoRules.maxPhotoBytes,
        'uploadsAvailable': true,
      },
      'schedule': {
        'asapAvailable': true,
        'slots': [
          for (final (from, to) in _slots())
            {'from': _iso(from), 'to': _iso(to)},
        ],
      },
      'fees': {'inspectionFee': null},
      'areas': await areas(),
    };
  }

  Row _address(Row a) => {
    'id': a['id'],
    'label': a['label'],
    'area': _area(a['areaId'] as String),
    'details': a['details'],
    'landmark': a['landmark'],
    if (a['lat'] != null)
      'location': {'latitude': a['lat'], 'longitude': a['lng']},
  };

  Future<List<Row>> addresses() async {
    await store.open();
    final me = store.requireUser({'customer'});
    return [
      for (final a in store.table('addresses'))
        if (a['userId'] == me['id']) _address(a),
    ];
  }

  Future<void> deleteAddress(String id) => store.write(() {
    final me = store.requireUser({'customer'});
    final removed = store.table('addresses').length;
    store
        .table('addresses')
        .removeWhere((a) => a['id'] == id && a['userId'] == me['id']);
    if (store.table('addresses').length == removed) {
      _fail('ADDRESS_NOT_FOUND', 404);
    }
  });

  // ---------------------------------------------------------------------------------------
  // Media (private: owner and the people working the request may read it)

  static String? sniffContentType(Uint8List bytes) {
    bool starts(List<int> magic) =>
        bytes.length >= magic.length &&
        Iterable<int>.generate(magic.length).every((i) => bytes[i] == magic[i]);
    if (starts([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (starts([0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (starts([0x25, 0x50, 0x44, 0x46])) return 'application/pdf';
    return null;
  }

  Future<Row> uploadMedia(String purpose, Uint8List bytes) async {
    await store.open();
    final me = store.requireUser();
    final type = sniffContentType(bytes) ?? _fail('UNSUPPORTED_FILE_TYPE', 415);
    if (purpose == 'request_photo' && !type.startsWith('image/')) {
      _fail('UNSUPPORTED_FILE_TYPE', 415);
    }
    final limit = type.startsWith('image/')
        ? DemoRules.maxPhotoBytes
        : 2 * DemoRules.maxPhotoBytes;
    if (bytes.length > limit) _fail('FILE_TOO_LARGE', 413);
    final id = store.newId('media');
    await store.writeBlob(id, bytes);
    return store.write(() {
      final row = {
        'id': id,
        'ownerId': me['id'],
        'purpose': purpose,
        'contentType': type,
        'byteSize': bytes.length,
        'attached': false,
      };
      store.table('media').add(row);
      return {'id': id, 'contentType': type, 'byteSize': bytes.length};
    });
  }

  Future<void> removeMedia(String id) async {
    final removed = await store.write(() {
      final me = store.requireUser();
      final m = store.find('media', id);
      if (m == null || m['ownerId'] != me['id'] || m['attached'] == true) {
        return false;
      }
      store.table('media').remove(m);
      return true;
    });
    if (removed) await store.deleteBlob(id);
  }

  Future<Uint8List> mediaContent(String id) async {
    await store.open();
    final me = store.requireUser();
    final m = store.find('media', id) ?? _fail('MEDIA_NOT_FOUND', 404);
    if (!_canSeeMedia(me, m)) _fail('MEDIA_NOT_FOUND', 404);
    return await store.readBlob(id) ?? _fail('MEDIA_NOT_FOUND', 404);
  }

  bool _canSeeMedia(Row me, Row media) {
    if (me['role'] == 'admin' || media['ownerId'] == me['id']) return true;
    for (final r in store.table('requests')) {
      if ((r['photoIds'] as List<dynamic>).contains(media['id']) &&
          _canSeeRequest(me, r)) {
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------------------
  // Requests

  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  String _reference() {
    final n = _now;
    String two(int v) => v.toString().padLeft(2, '0');
    final code = List.generate(
      5,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return 'SN-${two(n.year % 100)}${two(n.month)}${two(n.day)}-$code';
  }

  Row _summary(Row r) {
    final s = store.find('services', r['serviceId'] as String)!;
    final c = store.find('categories', s['categoryId'] as String)!;
    return {
      'id': r['id'],
      'reference': r['reference'],
      'status': r['status'],
      'service': {
        'id': s['id'],
        'slug': s['slug'],
        'name': s['name'],
        'category': {'name': c['name']},
      },
      'area': _area(r['areaId'] as String),
      'schedule': r['schedule'],
      'photoCount': (r['photoIds'] as List<dynamic>).length,
      'submittedAt': r['submittedAt'],
    };
  }

  Row _person(String id, {bool withRating = false}) {
    final u = store.find('users', id)!;
    final app = _applicationOf(id);
    final ratings = withRating ? _ratingsOf(id) : const <int>[];
    return {
      'id': id,
      'name': app?['fullName'] ?? u['name'] ?? '',
      'phone': u['phone'],
      if (ratings.isNotEmpty)
        'rating': ratings.reduce((a, b) => a + b) / ratings.length,
      'ratingCount': ratings.length,
    };
  }

  List<int> _ratingsOf(String technicianId) => [
    for (final r in store.table('requests'))
      if (r['technicianId'] == technicianId && r['rating'] != null)
        (r['rating'] as Map<String, dynamic>)['stars'] as int,
  ];

  Row? _pendingOfferFor(String requestId, String technicianId) {
    for (final o in store.table('offers')) {
      if (o['requestId'] == requestId &&
          o['technicianId'] == technicianId &&
          o['status'] == 'pending') {
        return o;
      }
    }
    return null;
  }

  Row _detail(Row r, Row viewer) {
    final s = store.find('services', r['serviceId'] as String)!;
    final isTechnicianView = viewer['role'] == 'technician';
    final offer = isTechnicianView
        ? _pendingOfferFor(r['id'] as String, viewer['id'] as String)
        : null;
    // An offered (not yet assigned) technician sees the area, not the exact address.
    final addressHidden = offer != null && r['technicianId'] != viewer['id'];
    return {
      ..._summary(r),
      'description': r['description'],
      'photos': [
        for (final id in r['photoIds'] as List<dynamic>) {'id': id},
      ],
      'location': {
        'area': _area(r['areaId'] as String),
        'details': addressHidden ? '' : r['details'],
        'landmark': addressHidden ? null : r['landmark'],
        if (!addressHidden && r['lat'] != null)
          'coordinates': {'latitude': r['lat'], 'longitude': r['lng']},
      },
      'pricing': s['pricing'],
      'fees': {'inspectionFee': null},
      'timeline': r['timeline'],
      if (viewer['role'] != 'customer' && !addressHidden)
        'customer': _person(r['customerId'] as String),
      if (r['technicianId'] != null)
        'technician': _person(r['technicianId'] as String, withRating: true),
      'quote': r['quote'],
      'payment': r['payment'],
      'rating': r['rating'],
      'cancelReason': r['cancelReason'],
      if (offer != null) 'offer': _offer(offer),
    };
  }

  Row _offer(Row o) => {
    'id': o['id'],
    'status': o['status'],
    'expiresAt': o['expiresAt'],
  };

  bool _canSeeRequest(Row me, Row r) => switch (me['role']) {
    'admin' => true,
    'customer' => r['customerId'] == me['id'],
    'technician' =>
      r['technicianId'] == me['id'] ||
          _pendingOfferFor(r['id'] as String, me['id'] as String) != null,
    _ => false,
  };

  Row _requireRequest(Row me, String id) {
    final r = store.find('requests', id);
    if (r == null || !_canSeeRequest(me, r)) _fail('REQUEST_NOT_FOUND', 404);
    return r;
  }

  Future<Row> submitRequest(Row body, String idempotencyKey) async {
    await store.open();
    final me = store.requireUser({'customer'});
    for (final k in store.table('idempotency')) {
      if (k['id'] == '${me['id']}:$idempotencyKey') {
        return _detail(store.find('requests', k['requestId'] as String)!, me);
      }
    }
    final service =
        store.find('services', body['serviceId'] as String) ??
        _fail('SERVICE_NOT_AVAILABLE', 422);
    final description = (body['description'] as String? ?? '').trim();
    if (description.length < 10 || description.length > 1000) {
      _fail('VALIDATION_FAILED');
    }
    final open = store
        .table('requests')
        .where(
          (r) =>
              r['customerId'] == me['id'] &&
              !parseStatusFinal(r['status'] as String),
        )
        .length;
    if (open >= DemoRules.maxOpenRequests) {
      _fail('TOO_MANY_OPEN_REQUESTS', 409);
    }

    final photoIds = (body['photoIds'] as List<dynamic>? ?? const [])
        .cast<String>();
    if (photoIds.length > DemoRules.maxPhotos) _fail('MEDIA_TOO_MANY', 422);
    for (final id in photoIds) {
      final m = store.find('media', id);
      if (m == null || m['ownerId'] != me['id'] || m['attached'] == true) {
        _fail('MEDIA_INVALID', 422);
      }
    }

    Row address;
    if (body['addressId'] case final String id) {
      final a = store.find('addresses', id);
      if (a == null || a['userId'] != me['id']) {
        _fail('ADDRESS_NOT_FOUND', 404);
      }
      address = a;
    } else if (body['address'] case final Map<String, dynamic> a) {
      if (store.find('areas', a['areaId'] as String) == null) {
        _fail('AREA_NOT_AVAILABLE', 422);
      }
      if ((a['details'] as String? ?? '').trim().length < 5) {
        _fail('VALIDATION_FAILED');
      }
      address = {
        'areaId': a['areaId'],
        'details': (a['details'] as String).trim(),
        'landmark': a['landmark'],
        'label': a['label'],
        'lat': a['latitude'],
        'lng': a['longitude'],
      };
    } else {
      _fail('LOCATION_REQUIRED');
    }

    final schedule = body['schedule'] as Map<String, dynamic>;
    if (schedule['type'] == 'scheduled' &&
        _date(schedule['from']).isBefore(_now)) {
      _fail('INVALID_SCHEDULE');
    }

    return store.write(() {
      if (body['saveAddress'] == true && body['address'] != null) {
        store.table('addresses').add({
          ...address,
          'id': store.newId('addr'),
          'userId': me['id'],
        });
      }
      for (final id in photoIds) {
        store.find('media', id)!['attached'] = true;
      }
      final now = _now;
      final request = <String, dynamic>{
        'id': store.newId('req'),
        'reference': _reference(),
        'customerId': me['id'],
        'serviceId': service['id'],
        'description': description,
        'photoIds': photoIds,
        'areaId': address['areaId'],
        'details': address['details'],
        'landmark': address['landmark'],
        'lat': address['lat'],
        'lng': address['lng'],
        'schedule': schedule,
        'status': 'submitted',
        'submittedAt': _iso(now),
        'technicianId': null,
        'timeline': [
          {'status': 'submitted', 'at': _iso(now)},
        ],
      };
      store.table('requests').add(request);
      store.table('idempotency').add({
        'id': '${me['id']}:$idempotencyKey',
        'requestId': request['id'],
      });
      _dispatch(request);
      return _detail(request, me);
    });
  }

  static bool parseStatusFinal(String status) =>
      status == 'completed' || status == 'cancelled';

  Future<Row> listRequests({String? cursor}) async {
    await _expireOffers();
    final me = store.requireUser({'customer'});
    final mine =
        store
            .table('requests')
            .where((r) => r['customerId'] == me['id'])
            .toList()
          ..sort(
            (a, b) => (b['submittedAt'] as String).compareTo(
              a['submittedAt'] as String,
            ),
          );
    return _page(mine, cursor);
  }

  Row _page(List<Row> rows, String? cursor, {int size = 20}) {
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = min(start + size, rows.length);
    return {
      'items': [for (final r in rows.sublist(start, end)) _summary(r)],
      'nextCursor': end < rows.length ? '$end' : null,
    };
  }

  Future<Row> getRequest(String id) async {
    await _expireOffers();
    final me = store.requireUser();
    return _detail(_requireRequest(me, id), me);
  }

  void _event(Row r, String status, {String? note}) {
    r['status'] = status;
    (r['timeline'] as List<dynamic>).add({
      'status': status,
      'at': _iso(_now),
      'note': ?note,
    });
  }

  void _notify(String userId, String type, {Row? request, String? appId}) {
    store.table('notifications').add({
      'id': store.newId('ntf'),
      'userId': userId,
      'type': type,
      if (request != null) 'requestId': request['id'],
      if (request != null) 'reference': request['reference'],
      'applicationId': ?appId,
      'at': _iso(_now),
      'read': false,
    });
  }

  void _notifyAdmins(String type, {Row? request, String? appId}) {
    for (final u in store.table('users')) {
      if (u['role'] == 'admin') {
        _notify(u['id'] as String, type, request: request, appId: appId);
      }
    }
  }

  Future<Row> cancelRequest(String id, String reason) => store.write(() {
    final me = store.requireUser({'customer', 'admin'});
    final r = _requireRequest(me, id);
    if (!parseRequestStatusCancellable(r['status'] as String)) {
      _fail('REQUEST_STATE_CONFLICT', 409);
    }
    if (reason.trim().isEmpty) _fail('VALIDATION_FAILED');
    r['cancelReason'] = reason.trim();
    _event(r, 'cancelled', note: me['role'] == 'admin' ? 'admin' : 'customer');
    _closeOffers(r, 'taken');
    if (r['technicianId'] case final String tech) {
      _notify(tech, 'request_cancelled', request: r);
    }
    if (me['role'] == 'admin') {
      _notify(r['customerId'] as String, 'request_cancelled', request: r);
    }
    return _detail(r, me);
  });

  static bool parseRequestStatusCancellable(String status) => const {
    'submitted',
    'unmatched',
    'assigned',
    'en_route',
    'arrived',
    'quoted',
    'quote_rejected',
  }.contains(status);

  Future<Row> decideQuote(String id, {required bool approve}) =>
      store.write(() {
        final me = store.requireUser({'customer'});
        final r = _requireRequest(me, id);
        final quote = r['quote'] as Map<String, dynamic>?;
        if (r['status'] != 'quoted' || quote == null) {
          _fail('REQUEST_STATE_CONFLICT', 409);
        }
        quote['status'] = approve ? 'approved' : 'rejected';
        if (approve) {
          _event(r, 'in_progress');
          _notify(r['technicianId'] as String, 'quote_approved', request: r);
        } else {
          _event(r, 'quote_rejected');
          _notify(r['technicianId'] as String, 'quote_rejected', request: r);
        }
        return _detail(r, me);
      });

  Future<Row> rate(String id, int stars, String? comment) => store.write(() {
    final me = store.requireUser({'customer'});
    final r = _requireRequest(me, id);
    if (r['status'] != 'completed' || r['rating'] != null) {
      _fail('REQUEST_STATE_CONFLICT', 409);
    }
    if (stars < 1 || stars > 5) _fail('VALIDATION_FAILED');
    final text = comment?.trim();
    r['rating'] = {
      'stars': stars,
      if (text != null && text.isNotEmpty) 'comment': text,
      'at': _iso(_now),
    };
    _notify(r['technicianId'] as String, 'rated', request: r);
    return _detail(r, me);
  });

  // ---------------------------------------------------------------------------------------
  // Dispatch (Sprint 3): eligible = approved, covers the category and the area.

  /// Approved technicians who cover [r]'s category and area, best rated first.
  List<String> eligibleTechnicians(Row r) {
    final service = store.find('services', r['serviceId'] as String)!;
    final candidates = [
      for (final a in store.table('applications'))
        if (a['status'] == 'approved' &&
            a['userId'] != r['customerId'] &&
            (a['specialtyIds'] as List<dynamic>).contains(
              service['categoryId'],
            ) &&
            (a['areaIds'] as List<dynamic>).contains(r['areaId']))
          a['userId'] as String,
    ];
    double score(String id) {
      final ratings = _ratingsOf(id);
      return ratings.isEmpty
          ? 4.0
          : ratings.reduce((a, b) => a + b) / ratings.length;
    }

    candidates.sort((a, b) => score(b).compareTo(score(a)));
    return candidates;
  }

  /// [Proposed] Offers go to the top three eligible technicians at once; the first to
  /// accept wins. With nobody eligible the request goes to operations as `unmatched`.
  void _dispatch(Row r) {
    final technicians = eligibleTechnicians(r).take(3).toList();
    if (technicians.isEmpty) {
      _event(r, 'unmatched');
      _notifyAdmins('request_unmatched', request: r);
      return;
    }
    final now = _now;
    for (final t in technicians) {
      store.table('offers').add({
        'id': store.newId('offer'),
        'requestId': r['id'],
        'technicianId': t,
        'status': 'pending',
        'createdAt': _iso(now),
        'expiresAt': _iso(
          now.add(const Duration(minutes: DemoRules.offerMinutes)),
        ),
      });
      _notify(t, 'new_offer', request: r);
    }
  }

  void _closeOffers(Row r, String status) {
    for (final o in store.table('offers')) {
      if (o['requestId'] == r['id'] && o['status'] == 'pending') {
        o['status'] = status;
      }
    }
  }

  /// Runs [_sweep] only when an offer has lapsed, so plain reads never write (and never
  /// wake listeners, which would reload and read again).
  Future<void> _expireOffers() async {
    await store.open();
    final now = _now;
    final due = store
        .table('offers')
        .any(
          (o) =>
              o['status'] == 'pending' && _date(o['expiresAt']).isBefore(now),
        );
    if (due) await store.write(_sweep);
  }

  /// Expires stale offers; a request whose offers all lapsed falls back to operations.
  void _sweep() {
    final now = _now;
    final touched = <String>{};
    for (final o in store.table('offers')) {
      if (o['status'] == 'pending' && _date(o['expiresAt']).isBefore(now)) {
        o['status'] = 'expired';
        touched.add(o['requestId'] as String);
      }
    }
    for (final id in touched) {
      final r = store.find('requests', id);
      if (r == null || r['status'] != 'submitted') continue;
      final stillPending = store
          .table('offers')
          .any((o) => o['requestId'] == id && o['status'] == 'pending');
      if (!stillPending) {
        _event(r, 'unmatched');
        _notifyAdmins('request_unmatched', request: r);
      }
    }
  }

  Future<List<Row>> offers() async {
    await _expireOffers();
    final me = store.requireUser({'technician'});
    final rows =
        store
            .table('offers')
            .where(
              (o) => o['technicianId'] == me['id'] && o['status'] == 'pending',
            )
            .toList()
          ..sort(
            (a, b) =>
                (a['expiresAt'] as String).compareTo(b['expiresAt'] as String),
          );
    return [
      for (final o in rows)
        {
          ..._summary(store.find('requests', o['requestId'] as String)!),
          'offer': _offer(o),
        },
    ];
  }

  /// Accepting is atomic: the first technician to accept takes the request.
  Future<Row> respondToOffer(String offerId, {required bool accept}) async {
    await _expireOffers();
    return store.write(() {
      final me = store.requireUser({'technician'});
      final o = store.find('offers', offerId);
      if (o == null || o['technicianId'] != me['id']) {
        _fail('NOT_FOUND', 404);
      }
      final r = store.find('requests', o['requestId'] as String)!;
      if (o['status'] != 'pending') {
        _fail(o['status'] == 'expired' ? 'OFFER_EXPIRED' : 'OFFER_TAKEN', 409);
      }
      if (!accept) {
        o['status'] = 'declined';
        final stillPending = store
            .table('offers')
            .any((x) => x['requestId'] == r['id'] && x['status'] == 'pending');
        if (!stillPending && r['status'] == 'submitted') {
          _event(r, 'unmatched');
          _notifyAdmins('request_unmatched', request: r);
        }
        return _summary(r);
      }
      if (r['status'] != 'submitted') _fail('OFFER_TAKEN', 409);
      o['status'] = 'accepted';
      _closeOffers(r, 'taken');
      r['technicianId'] = me['id'];
      _event(r, 'assigned');
      _notify(r['customerId'] as String, 'assigned', request: r);
      return _detail(r, me);
    });
  }

  Future<Row> jobs({required bool active}) async {
    await _expireOffers();
    final me = store.requireUser({'technician'});
    final rows =
        store
            .table('requests')
            .where(
              (r) =>
                  r['technicianId'] == me['id'] &&
                  parseStatusFinal(r['status'] as String) != active,
            )
            .toList()
          ..sort(
            (a, b) => (b['submittedAt'] as String).compareTo(
              a['submittedAt'] as String,
            ),
          );
    return _page(rows, null, size: 100);
  }

  static const _technicianSteps = {
    'en_route': {'assigned'},
    'arrived': {'en_route'},
    'completed': {'in_progress'},
  };

  /// Moves an assigned job forward: on the way → arrived → (quote) → completed.
  Future<Row> advanceJob(String id, String to) => store.write(() {
    final me = store.requireUser({'technician'});
    final r = _requireRequest(me, id);
    final from = _technicianSteps[to];
    if (r['technicianId'] != me['id'] ||
        from == null ||
        !from.contains(r['status'])) {
      _fail('REQUEST_STATE_CONFLICT', 409);
    }
    if (to == 'completed') {
      final amount = (r['quote'] as Map<String, dynamic>)['amountMinor'] as int;
      r['payment'] = {
        'amountMinor': amount,
        'commissionMinor': (amount * DemoRules.commissionPercent / 100).round(),
        'at': _iso(_now),
      };
    }
    _event(r, to);
    _notify(r['customerId'] as String, to, request: r);
    return _detail(r, me);
  });

  Future<Row> sendQuote(String id, int amountMinor, String? note) =>
      store.write(() {
        final me = store.requireUser({'technician'});
        final r = _requireRequest(me, id);
        if (r['technicianId'] != me['id'] ||
            !const {'arrived', 'quote_rejected'}.contains(r['status'])) {
          _fail('REQUEST_STATE_CONFLICT', 409);
        }
        if (amountMinor <= 0 || amountMinor > 10000000) {
          _fail('VALIDATION_FAILED');
        }
        final text = note?.trim();
        r['quote'] = {
          'amountMinor': amountMinor,
          if (text != null && text.isNotEmpty) 'note': text,
          'status': 'pending',
          'at': _iso(_now),
        };
        _event(r, 'quoted');
        _notify(r['customerId'] as String, 'quoted', request: r);
        return _detail(r, me);
      });

  /// Collected cash and commission owed, from completed jobs.
  Future<Row> earnings() async {
    await store.open();
    final me = store.requireUser({'technician'});
    var collected = 0;
    var commission = 0;
    var count = 0;
    for (final r in store.table('requests')) {
      if (r['technicianId'] == me['id'] && r['payment'] != null) {
        final p = r['payment'] as Map<String, dynamic>;
        collected += p['amountMinor'] as int;
        commission += p['commissionMinor'] as int;
        count++;
      }
    }
    final ratings = _ratingsOf(me['id'] as String);
    return {
      'jobs': count,
      'collectedMinor': collected,
      'commissionMinor': commission,
      'rating': ratings.isEmpty
          ? null
          : ratings.reduce((a, b) => a + b) / ratings.length,
      'ratingCount': ratings.length,
    };
  }

  // ---------------------------------------------------------------------------------------
  // Chat (order-bound; customer and assigned technician write, admins read)

  Future<List<Row>> messages(String requestId) async {
    await store.open();
    final me = store.requireUser();
    final r = _requireRequest(me, requestId);
    if (!_chatVisible(me, r)) _fail('FORBIDDEN', 403);
    return [
      for (final m in store.table('messages'))
        if (m['requestId'] == requestId)
          {
            'id': m['id'],
            'text': m['text'],
            'at': m['at'],
            'senderId': m['senderId'],
            'senderRole': store.find('users', m['senderId'] as String)!['role'],
            'mine': m['senderId'] == me['id'],
          },
    ];
  }

  bool _chatVisible(Row me, Row r) =>
      me['role'] == 'admin' ||
      (r['technicianId'] != null &&
          (r['customerId'] == me['id'] || r['technicianId'] == me['id']));

  Future<void> sendMessage(String requestId, String text) => store.write(() {
    final me = store.requireUser({'customer', 'technician'});
    final r = _requireRequest(me, requestId);
    final status = r['status'] as String;
    if (!_chatVisible(me, r) || parseStatusFinal(status)) {
      _fail('FORBIDDEN', 403);
    }
    final body = text.trim();
    if (body.isEmpty || body.length > 1000) _fail('VALIDATION_FAILED');
    store.table('messages').add({
      'id': store.newId('msg'),
      'requestId': requestId,
      'senderId': me['id'],
      'text': body,
      'at': _iso(_now),
    });
    final other = me['id'] == r['customerId']
        ? r['technicianId'] as String
        : r['customerId'] as String;
    // One unread chat notice per conversation is enough.
    final hasUnread = store
        .table('notifications')
        .any(
          (n) =>
              n['userId'] == other &&
              n['type'] == 'message' &&
              n['requestId'] == requestId &&
              n['read'] == false,
        );
    if (!hasUnread) _notify(other, 'message', request: r);
  });

  // ---------------------------------------------------------------------------------------
  // Notifications

  List<Row> _myNotifications() {
    final me = store.sessionUser;
    if (me == null) return const [];
    return store
        .table('notifications')
        .where((n) => n['userId'] == me['id'])
        .toList()
      ..sort((a, b) => (b['at'] as String).compareTo(a['at'] as String));
  }

  /// Synchronous so badges can rebuild on every store change.
  int unreadCount() =>
      _myNotifications().where((n) => n['read'] != true).length;

  Future<List<Row>> notifications() async {
    await _expireOffers();
    store.requireUser();
    return _myNotifications();
  }

  Future<void> markNotificationsRead() => store.write(() {
    for (final n in _myNotifications()) {
      n['read'] = true;
    }
  });

  // ---------------------------------------------------------------------------------------
  // Technician applications (Sprint 2)

  Row? _applicationOf(String userId) {
    for (final a in store.table('applications')) {
      if (a['userId'] == userId) return a;
    }
    return null;
  }

  Row _application(Row a) {
    final status = a['status'] as String;
    return {
      'id': a['id'],
      'status': status,
      'fullName': a['fullName'],
      'yearsOfExperience': a['yearsOfExperience'],
      'bio': a['bio'],
      'specialties': [
        for (final id in a['specialtyIds'] as List<dynamic>)
          if (store.find('categories', id as String) case final c?)
            {'id': c['id'], 'slug': c['slug'], 'name': c['name']},
      ],
      'serviceAreas': [
        for (final id in a['areaIds'] as List<dynamic>) _area(id as String),
      ],
      'documents': [
        for (final d in a['documents'] as List<dynamic>)
          if (store.find(
                'media',
                (d as Map<String, dynamic>)['mediaId'] as String,
              )
              case final m?)
            {
              'id': m['id'],
              'kind': d['kind'],
              'contentType': m['contentType'],
              'byteSize': m['byteSize'],
            },
      ],
      'submittedAt': a['submittedAt'],
      'reviewedAt': a['reviewedAt'],
      'decisionReason': a['decisionReason'],
      'canResubmit': status == 'rejected',
      'eligibleForWork': status == 'approved',
    };
  }

  static const _requirements = {
    'minDocuments': 0,
    'maxDocuments': 5,
    'uploadsAvailable': true,
  };

  Future<Row> ownApplication() async {
    await store.open();
    final me = store.requireUser({'customer', 'technician'});
    final a = _applicationOf(me['id'] as String);
    return {
      'application': a == null ? null : _application(a),
      'requirements': _requirements,
    };
  }

  Future<Row> submitApplication(Row body) => store.write(() {
    final me = store.requireUser({'customer', 'technician'});
    final existing = _applicationOf(me['id'] as String);
    if (existing != null && existing['status'] != 'rejected') {
      _fail('APPLICATION_ALREADY_SUBMITTED', 409);
    }
    final fullName = (body['fullName'] as String? ?? '').trim();
    final specialties = (body['specialtyCategoryIds'] as List<dynamic>)
        .cast<String>();
    final areaIds = (body['serviceAreaIds'] as List<dynamic>).cast<String>();
    if (fullName.length < 3 || specialties.isEmpty || areaIds.isEmpty) {
      _fail('VALIDATION_FAILED');
    }
    if (specialties.any((id) => store.find('categories', id) == null)) {
      _fail('CATEGORY_NOT_AVAILABLE', 422);
    }
    if (areaIds.any((id) => store.find('areas', id) == null)) {
      _fail('AREA_NOT_AVAILABLE', 422);
    }
    final documents = (body['documents'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    for (final d in documents) {
      final m = store.find('media', d['mediaId'] as String);
      if (m == null || m['ownerId'] != me['id']) _fail('MEDIA_INVALID', 422);
      m['attached'] = true;
    }
    final now = _iso(_now);
    final row =
        existing ??
        <String, dynamic>{
          'id': store.newId('app'),
          'userId': me['id'],
          'history': <dynamic>[],
        };
    row
      ..['status'] = 'pending_review'
      ..['fullName'] = fullName
      ..['yearsOfExperience'] = body['yearsOfExperience']
      ..['bio'] = body['bio']
      ..['specialtyIds'] = specialties
      ..['areaIds'] = areaIds
      ..['documents'] = documents
      ..['submittedAt'] = now
      ..['reviewedAt'] = null
      ..['decisionReason'] = null;
    (row['history'] as List<dynamic>).add({
      'action': existing == null ? 'submitted' : 'resubmitted',
      'at': now,
    });
    if (existing == null) store.table('applications').add(row);
    _notifyAdmins('application_submitted', appId: row['id'] as String);
    return {'application': _application(row)};
  });

  // ---------------------------------------------------------------------------------------
  // Admin (operations)

  Future<List<Row>> listApplications(String status) async {
    await store.open();
    store.requireUser({'admin'});
    final rows =
        store.table('applications').where((a) => a['status'] == status).toList()
          ..sort(
            (a, b) => (b['submittedAt'] as String).compareTo(
              a['submittedAt'] as String,
            ),
          );
    return [
      for (final a in rows)
        {
          'id': a['id'],
          'status': a['status'],
          'fullName': a['fullName'],
          'specialtyCount': (a['specialtyIds'] as List<dynamic>).length,
          'areaCount': (a['areaIds'] as List<dynamic>).length,
          'documentCount': (a['documents'] as List<dynamic>).length,
          'submittedAt': a['submittedAt'],
        },
    ];
  }

  Row _review(Row a) {
    final u = store.find('users', a['userId'] as String)!;
    return {
      ..._application(a),
      'applicant': {'phone': u['phone'], 'accountName': u['name']},
      'history': a['history'],
    };
  }

  Future<Row> getApplication(String id) async {
    await store.open();
    store.requireUser({'admin'});
    return _review(store.require('applications', id, 'APPLICATION_NOT_FOUND'));
  }

  Future<Row> decideApplication(
    String id,
    String action,
    String? reason,
  ) => store.write(() {
    final me = store.requireUser({'admin'});
    final a = store.require('applications', id, 'APPLICATION_NOT_FOUND');
    if (a['userId'] == me['id']) _fail('CANNOT_REVIEW_OWN_APPLICATION', 403);
    final from = a['status'] as String;
    final to = switch (action) {
      'approve' when from == 'pending_review' || from == 'suspended' =>
        'approved',
      'reject' when from == 'pending_review' => 'rejected',
      'suspend' when from == 'approved' => 'suspended',
      _ => _fail('APPLICATION_STATE_CONFLICT', 409),
    };
    final text = reason?.trim();
    if (action != 'approve' && (text == null || text.isEmpty)) {
      _fail('VALIDATION_FAILED');
    }
    final now = _iso(_now);
    a
      ..['status'] = to
      ..['reviewedAt'] = now
      ..['decisionReason'] = action == 'approve' ? null : text;
    (a['history'] as List<dynamic>).add({
      'action': to,
      'at': now,
      if (text != null && text.isNotEmpty) 'reason': text,
    });
    if (to == 'approved') {
      store.find('users', a['userId'] as String)!['role'] = 'technician';
    }
    _notify(a['userId'] as String, 'application_$to', appId: a['id'] as String);
    return _review(a);
  });

  Future<Row> adminOverview() async {
    await _expireOffers();
    store.requireUser({'admin'});
    final counts = <String, int>{};
    for (final r in store.table('requests')) {
      counts.update(r['status'] as String, (v) => v + 1, ifAbsent: () => 1);
    }
    final revenue = store
        .table('requests')
        .where((r) => r['payment'] != null)
        .fold<int>(
          0,
          (sum, r) =>
              sum +
              ((r['payment'] as Map<String, dynamic>)['commissionMinor']
                  as int),
        );
    return {
      'statusCounts': counts,
      'pendingApplications': store
          .table('applications')
          .where((a) => a['status'] == 'pending_review')
          .length,
      'approvedTechnicians': store
          .table('applications')
          .where((a) => a['status'] == 'approved')
          .length,
      'commissionMinor': revenue,
    };
  }

  Future<List<Row>> adminRequests(Set<String> statuses) async {
    await _expireOffers();
    store.requireUser({'admin'});
    final rows =
        store
            .table('requests')
            .where((r) => statuses.isEmpty || statuses.contains(r['status']))
            .toList()
          ..sort(
            (a, b) => (b['submittedAt'] as String).compareTo(
              a['submittedAt'] as String,
            ),
          );
    return [for (final r in rows) _summary(r)];
  }

  Future<List<Row>> assignableTechnicians(String requestId) async {
    await store.open();
    store.requireUser({'admin'});
    final r = store.require('requests', requestId, 'REQUEST_NOT_FOUND');
    return [
      for (final id in eligibleTechnicians(r)) _person(id, withRating: true),
    ];
  }

  /// Operations fallback: assign a request nobody accepted to an eligible technician.
  Future<Row> assign(String requestId, String technicianId) => store.write(() {
    final me = store.requireUser({'admin'});
    final r = store.require('requests', requestId, 'REQUEST_NOT_FOUND');
    if (!const {'submitted', 'unmatched'}.contains(r['status'])) {
      _fail('REQUEST_STATE_CONFLICT', 409);
    }
    if (!eligibleTechnicians(r).contains(technicianId)) {
      _fail('TECHNICIAN_NOT_ELIGIBLE', 422);
    }
    _closeOffers(r, 'taken');
    r['technicianId'] = technicianId;
    _event(r, 'assigned', note: 'admin');
    _notify(technicianId, 'assigned_by_admin', request: r);
    _notify(r['customerId'] as String, 'assigned', request: r);
    return _detail(r, me);
  });
}
