/// What a brand-new database contains: the service catalog and the Aswan service areas.
///
/// There are deliberately no accounts, requests, reviews, chats or notifications here; those
/// only ever come from people using the app. Indicative prices are guidance shown to the
/// customer before a technician inspects and quotes; the quote is what is agreed.
library;

import '../core/storage/local_store.dart';

/// Business rules in one place. Values marked [Proposed] await product sign-off.
abstract final class AppRules {
  /// [Proposed] How long a technician has to accept an offer.
  static const offerMinutes = 15;

  /// [Proposed] Platform commission on the collected amount, in percent.
  static const commissionPercent = 10;
  static const maxPhotos = 5;
  static const maxPhotoBytes = 5 * 1024 * 1024;
  static const maxOpenRequests = 5;

  /// Password policy: at least this many characters, with a letter and a digit.
  static const minPasswordLength = 8;

  /// [Proposed] Failed sign-ins allowed per phone number before a short lock-out.
  static const maxFailedSignIns = 5;
  static const signInLockMinutes = 5;
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

/// A fresh database: catalog and service areas only.
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
    });
    for (final s in c.$6) {
      services.add({
        'id': 'svc-${s.$1}',
        'slug': s.$1,
        'categoryId': 'cat-${c.$1}',
        'name': _text(s.$2, s.$3),
        'description': _text(s.$4, s.$5),
        'pricing': _price(s.$6, s.$7),
      });
    }
  }
  return {
    'version': LocalStore.schemaVersion,
    'createdAt': now.toUtc().toIso8601String(),
    'session': null,
    'seq': 0,
    'onboardingSeen': false,
    'users': <Row>[],
    'categories': categories,
    'services': services,
    'areas': [
      for (final a in _areas)
        {'id': 'area-${a.$1}', 'slug': a.$1, 'name': _text(a.$2, a.$3)},
    ],
    'addresses': <Row>[],
    'media': <Row>[],
    'applications': <Row>[],
    'requests': <Row>[],
    'offers': <Row>[],
    'messages': <Row>[],
    'notifications': <Row>[],
    'idempotency': <Row>[],
  };
}
