/// Seed data for the standalone demo: three sign-in accounts (customer, technician, admin),
/// the sample Aswan catalog, and a few records so every screen has something to show.
///
/// Everything here is sample data for a school project. Prices are illustrative only.
library;

import '../core/storage/local_store.dart';

abstract final class DemoIds {
  static const customer = 'u-customer';
  static const technician = 'u-technician';
  static const admin = 'u-admin';
}

/// Tunable demo rules, stored with the data so they could be edited in one place.
abstract final class AppRules {
  /// [Proposed] How long a technician has to accept an offer.
  static const offerMinutes = 15;

  /// [Proposed] Platform commission on the collected amount, in percent.
  static const commissionPercent = 10;
  static const maxPhotos = 5;
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const maxOpenRequests = 5;
  static const scheduleLeadMinutes = 120;
  static const scheduleDaysAhead = 7;

  /// Local appointment windows, in minutes from midnight.
  static const slotWindows = [
    (9 * 60, 12 * 60),
    (12 * 60, 15 * 60),
    (15 * 60, 18 * 60),
    (18 * 60, 21 * 60),
  ];
}

Row _text(String ar, String en) => {'ar': ar, 'en': en};

Row _price(int? minEgp, int? maxEgp) => minEgp == null
    ? {'type': 'inspection_required', 'currency': 'EGP'}
    : {
        'type': 'indicative',
        'minMinor': minEgp * 100,
        'maxMinor': maxEgp! * 100,
        'currency': 'EGP',
      };

const _areas = [
  ('aswan-city-centre', 'وسط مدينة أسوان', 'Aswan City Centre'),
  ('el-sahary', 'الصحاري', 'El Sahary'),
  ('kima', 'كيما', 'Kima'),
  ('el-seil', 'السيل', 'El Seil'),
  ('atlas', 'أطلس', 'Atlas'),
  ('west-aswan', 'غرب أسوان', 'West Aswan'),
];

typedef _Service = (
  String slug,
  String ar,
  String en,
  String descAr,
  String descEn,
  int? minEgp,
  int? maxEgp,
);

typedef _Category = (
  String slug,
  String ar,
  String en,
  String descAr,
  String descEn,
  List<_Service> services,
);

const List<_Category> _catalog = [
  (
    'plumbing',
    'سباكة',
    'Plumbing',
    'إصلاح التسريبات والحنفيات والسخانات وشبكات المياه.',
    'Leaks, taps, water heaters and water lines.',
    [
      (
        'plumbing-leak-repair',
        'إصلاح تسريب مياه',
        'Water leak repair',
        'كشف وإصلاح تسريبات المواسير والوصلات.',
        'Find and fix leaking pipes and joints.',
        150,
        400,
      ),
      (
        'plumbing-tap-replacement',
        'تركيب أو تغيير حنفية',
        'Tap installation or replacement',
        'تركيب حنفيات المطبخ والحمام أو استبدالها.',
        'Install or replace kitchen and bathroom taps.',
        100,
        250,
      ),
      (
        'plumbing-water-heater',
        'صيانة سخان مياه',
        'Water heater service',
        'فحص وصيانة سخانات المياه الكهربائية والغاز.',
        'Inspect and service electric and gas water heaters.',
        null,
        null,
      ),
    ],
  ),
  (
    'electrical',
    'كهرباء',
    'Electrical',
    'الأعطال الكهربائية والإنارة والمفاتيح والبرايز.',
    'Electrical faults, lighting, switches and sockets.',
    [
      (
        'electrical-fault-diagnosis',
        'كشف عطل كهربائي',
        'Electrical fault diagnosis',
        'تحديد سبب انقطاع الكهرباء أو فصل القاطع وإصلاحه.',
        'Find and fix the cause of power cuts or tripping breakers.',
        null,
        null,
      ),
      (
        'electrical-lighting-install',
        'تركيب إنارة',
        'Lighting installation',
        'تركيب النجف والكشافات ووحدات الإضاءة.',
        'Install ceiling lights, spotlights and fixtures.',
        120,
        350,
      ),
    ],
  ),
  (
    'air-conditioning',
    'تكييف',
    'Air conditioning',
    'صيانة وتنظيف وشحن أجهزة التكييف.',
    'AC servicing, cleaning and refrigerant recharge.',
    [
      (
        'ac-cleaning',
        'تنظيف وصيانة تكييف',
        'AC cleaning and service',
        'تنظيف الفلاتر والوحدات الداخلية والخارجية وفحص الأداء.',
        'Clean filters and indoor/outdoor units and check performance.',
        250,
        450,
      ),
      (
        'ac-not-cooling',
        'تكييف لا يبرّد',
        'AC not cooling',
        'فحص أسباب ضعف التبريد وإصلاحها.',
        'Diagnose and fix weak or no cooling.',
        null,
        null,
      ),
    ],
  ),
  (
    'carpentry',
    'نجارة',
    'Carpentry',
    'إصلاح الأبواب والأثاث والأقفال والدواليب.',
    'Doors, furniture, locks and cabinets.',
    [
      (
        'carpentry-door-repair',
        'إصلاح باب',
        'Door repair',
        'ضبط الأبواب وتغيير المفصلات والأكر.',
        'Adjust doors and replace hinges and handles.',
        150,
        500,
      ),
    ],
  ),
  (
    'painting',
    'نقاشة ودهانات',
    'Painting',
    'دهان الحوائط والأسقف والمعالجة البسيطة للشروخ.',
    'Wall and ceiling painting and minor crack repair.',
    [
      (
        'painting-room',
        'دهان غرفة',
        'Room painting',
        'تجهيز ودهان حوائط وسقف غرفة.',
        'Prepare and paint the walls and ceiling of a room.',
        null,
        null,
      ),
    ],
  ),
  (
    'appliances',
    'أجهزة منزلية',
    'Home appliances',
    'صيانة الغسالات والثلاجات والأجهزة المنزلية.',
    'Washing machines, fridges and other appliances.',
    [
      (
        'appliance-washing-machine',
        'صيانة غسالة',
        'Washing machine repair',
        'فحص وإصلاح أعطال الغسالات الأوتوماتيك والعادية.',
        'Diagnose and repair automatic and twin-tub washers.',
        200,
        600,
      ),
      (
        'appliance-refrigerator',
        'صيانة ثلاجة',
        'Refrigerator repair',
        'فحص ضعف التبريد والتسريب والأصوات المزعجة.',
        'Weak cooling, leaks and noisy operation.',
        null,
        null,
      ),
    ],
  ),
];

String _iso(DateTime t) => t.toUtc().toIso8601String();

/// A fresh demo database relative to [now].
Row buildInitialData(DateTime now) {
  final categories = <Row>[];
  final services = <Row>[];
  for (final (i, c) in _catalog.indexed) {
    categories.add({
      'id': 'cat-${c.$1}',
      'slug': c.$1,
      'name': _text(c.$2, c.$3),
      'description': _text(c.$4, c.$5),
      'iconKey': c.$1 == 'air-conditioning' ? 'air_conditioning' : c.$1,
      'sortOrder': i,
      'isSample': true,
    });
    for (final s in c.$6) {
      services.add({
        'id': 'svc-${s.$1}',
        'slug': s.$1,
        'categoryId': 'cat-${c.$1}',
        'name': _text(s.$2, s.$3),
        'description': _text(s.$4, s.$5),
        'pricing': _price(s.$6, s.$7),
        'isSample': true,
      });
    }
  }
  final areas = [
    for (final a in _areas)
      {
        'id': 'area-${a.$1}',
        'slug': a.$1,
        'name': _text(a.$2, a.$3),
        'isSample': true,
      },
  ];

  Row user(String id, String phone, String name, String role) => {
    'id': id,
    'phone': phone,
    'name': name,
    'role': role,
  };

  final ago = now.subtract;
  Row application(
    String id,
    String userId,
    String status,
    String fullName,
    int years,
    String bio,
    List<String> categorySlugs,
    List<String> areaSlugs,
    DateTime submittedAt,
  ) => {
    'id': id,
    'userId': userId,
    'status': status,
    'fullName': fullName,
    'yearsOfExperience': years,
    'bio': bio,
    'specialtyIds': [for (final s in categorySlugs) 'cat-$s'],
    'areaIds': [for (final s in areaSlugs) 'area-$s'],
    'documents': <Row>[],
    'submittedAt': _iso(submittedAt),
    'reviewedAt': status == 'approved'
        ? _iso(submittedAt.add(const Duration(days: 1)))
        : null,
    'decisionReason': null,
    'history': [
      {'action': 'submitted', 'at': _iso(submittedAt)},
      if (status == 'approved')
        {
          'action': 'approved',
          'at': _iso(submittedAt.add(const Duration(days: 1))),
        },
    ],
  };

  final allCategories = [for (final c in _catalog) c.$1];
  final allAreas = [for (final a in _areas) a.$1];

  // A finished job (rated) and an open request waiting on the demo technician.
  final doneAt = ago(const Duration(days: 3));
  Row event(String status, DateTime at) => {'status': status, 'at': _iso(at)};
  final completed = <String, dynamic>{
    'id': 'req-demo-1',
    'reference': 'SN-DEMO-0001',
    'customerId': DemoIds.customer,
    'serviceId': 'svc-ac-cleaning',
    'description': 'التكييف يحتاج تنظيف قبل الصيف، والفلتر عليه أتربة كثيرة.',
    'photoIds': <String>[],
    'areaId': 'area-aswan-city-centre',
    'details': 'شارع كورنيش النيل، عمارة ١٢، الدور الثالث',
    'landmark': 'بجوار فندق كتراكت',
    'schedule': {'type': 'asap'},
    'status': 'completed',
    'submittedAt': _iso(doneAt),
    'technicianId': DemoIds.technician,
    'quote': {
      'amountMinor': 35000,
      'note': 'تنظيف كامل للوحدتين وتغيير فلتر.',
      'status': 'approved',
      'at': _iso(doneAt.add(const Duration(hours: 2))),
    },
    'payment': {
      'amountMinor': 35000,
      'commissionMinor': 3500,
      'at': _iso(doneAt.add(const Duration(hours: 4))),
    },
    'rating': {
      'stars': 5,
      'comment': 'فني محترم وشغله نظيف.',
      'at': _iso(doneAt.add(const Duration(hours: 5))),
    },
    'timeline': [
      event('submitted', doneAt),
      event('assigned', doneAt.add(const Duration(minutes: 6))),
      event('en_route', doneAt.add(const Duration(minutes: 40))),
      event('arrived', doneAt.add(const Duration(hours: 1, minutes: 30))),
      event('quoted', doneAt.add(const Duration(hours: 2))),
      event('in_progress', doneAt.add(const Duration(hours: 2, minutes: 5))),
      event('completed', doneAt.add(const Duration(hours: 4))),
    ],
  };
  final openAt = ago(const Duration(minutes: 3));
  final open = <String, dynamic>{
    'id': 'req-demo-2',
    'reference': 'SN-DEMO-0002',
    'customerId': DemoIds.customer,
    'serviceId': 'svc-plumbing-leak-repair',
    'description': 'في تسريب مياه تحت حوض المطبخ والأرضية بتتبل باستمرار.',
    'photoIds': <String>[],
    'areaId': 'area-el-sahary',
    'details': 'الصحاري، شارع المدارس، منزل ٤',
    'landmark': null,
    'schedule': {'type': 'asap'},
    'status': 'submitted',
    'submittedAt': _iso(openAt),
    'technicianId': null,
    'timeline': [event('submitted', openAt)],
  };

  return {
    'version': LocalStore.schemaVersion,
    'session': null,
    'seq': 0,
    'users': [
      user(DemoIds.customer, '+201001234567', 'أحمد محمود', 'customer'),
      user(DemoIds.technician, '+201112345678', 'محمد علي', 'technician'),
      user(DemoIds.admin, '+201223456789', 'منى حسن', 'admin'),
      user('u-karim', '+201098765432', 'كريم فؤاد', 'technician'),
      user('u-sami', '+201155544433', 'سامي يوسف', 'customer'),
      user('u-khaled', '+201277788899', 'خالد عبد الرحمن', 'customer'),
    ],
    'categories': categories,
    'services': services,
    'areas': areas,
    'addresses': [
      {
        'id': 'addr-demo-1',
        'userId': DemoIds.customer,
        'label': 'البيت',
        'areaId': 'area-aswan-city-centre',
        'details': 'شارع كورنيش النيل، عمارة ١٢، الدور الثالث',
        'landmark': 'بجوار فندق كتراكت',
      },
    ],
    'media': <Row>[],
    'applications': [
      application(
        'app-technician',
        DemoIds.technician,
        'approved',
        'محمد علي حسن',
        8,
        'فني صيانة منزلية متعدد الخبرات في أسوان.',
        allCategories,
        allAreas,
        ago(const Duration(days: 30)),
      ),
      application(
        'app-karim',
        'u-karim',
        'approved',
        'كريم فؤاد',
        5,
        'سباك ونقاش.',
        ['plumbing', 'painting'],
        ['aswan-city-centre', 'el-sahary'],
        ago(const Duration(days: 20)),
      ),
      application(
        'app-sami',
        'u-sami',
        'pending_review',
        'سامي يوسف',
        3,
        'كهربائي منازل، خبرة في التأسيس والإنارة.',
        ['electrical'],
        ['kima', 'el-seil'],
        ago(const Duration(hours: 20)),
      ),
      application(
        'app-khaled',
        'u-khaled',
        'pending_review',
        'خالد عبد الرحمن',
        6,
        'فني تكييف وتبريد.',
        ['air-conditioning', 'appliances'],
        ['atlas', 'west-aswan', 'aswan-city-centre'],
        ago(const Duration(hours: 5)),
      ),
    ],
    'requests': [completed, open],
    'offers': [
      for (final tech in [DemoIds.technician, 'u-karim'])
        {
          'id': 'offer-demo-$tech',
          'requestId': 'req-demo-2',
          'technicianId': tech,
          'status': 'pending',
          'createdAt': _iso(openAt),
          'expiresAt': _iso(
            openAt.add(const Duration(minutes: AppRules.offerMinutes)),
          ),
        },
    ],
    'messages': [
      {
        'id': 'msg-demo-1',
        'requestId': 'req-demo-1',
        'senderId': DemoIds.technician,
        'text': 'أنا في الطريق، حوالي ٢٠ دقيقة.',
        'at': _iso(doneAt.add(const Duration(minutes: 41))),
      },
      {
        'id': 'msg-demo-2',
        'requestId': 'req-demo-1',
        'senderId': DemoIds.customer,
        'text': 'تمام، في انتظارك.',
        'at': _iso(doneAt.add(const Duration(minutes: 43))),
      },
    ],
    'notifications': [
      {
        'id': 'ntf-demo-1',
        'userId': DemoIds.technician,
        'type': 'new_offer',
        'requestId': 'req-demo-2',
        'reference': 'SN-DEMO-0002',
        'at': _iso(openAt),
        'read': false,
      },
      {
        'id': 'ntf-demo-2',
        'userId': DemoIds.admin,
        'type': 'application_submitted',
        'applicationId': 'app-khaled',
        'at': _iso(ago(const Duration(hours: 5))),
        'read': false,
      },
    ],
  };
}
