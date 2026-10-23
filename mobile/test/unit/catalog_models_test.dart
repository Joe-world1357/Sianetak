import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/catalog/domain/catalog_models.dart';

void main() {
  group('PricingGuidance.fromJson', () {
    test('parses an approved indicative range', () {
      final pricing = PricingGuidance.fromJson({
        'type': 'indicative',
        'currency': 'EGP',
        'minMinor': 15000,
        'maxMinor': 30000,
      });
      expect(pricing.type, PricingType.indicative);
      expect(pricing.minMinor, 15000);
      expect(pricing.maxMinor, 30000);
    });

    test('never invents a price from malformed data', () {
      for (final json in <Object?>[
        {'type': 'inspection_required', 'currency': 'EGP'},
        {'type': 'indicative', 'minMinor': 100},
        {'type': 'indicative', 'minMinor': 500, 'maxMinor': 100},
        {'type': 'indicative', 'minMinor': 0, 'maxMinor': 100},
        {'type': 'indicative', 'minMinor': '100', 'maxMinor': '200'},
        {'type': 'something-new'},
        null,
      ]) {
        final pricing = PricingGuidance.fromJson(json);
        expect(pricing.type, PricingType.inspectionRequired, reason: '$json');
        expect(pricing.minMinor, isNull);
      }
    });
  });

  group('LocalizedText', () {
    test('resolves by language and falls back to the other language', () {
      final both = LocalizedText.fromJson({'ar': 'سباكة', 'en': 'Plumbing'});
      expect(both.resolve('ar'), 'سباكة');
      expect(both.resolve('en'), 'Plumbing');
      final arOnly = LocalizedText.fromJson({'ar': 'سباكة', 'en': ''});
      expect(arOnly.resolve('en'), 'سباكة');
    });
  });

  test('ServiceCategory tolerates missing optional fields', () {
    final c = ServiceCategory.fromJson({
      'id': 'c1',
      'slug': 'plumbing',
      'name': {'ar': 'سباكة', 'en': 'Plumbing'},
    });
    expect(c.serviceCount, 0);
    expect(c.isSample, isFalse);
    expect(c.description, isNull);
  });
}
