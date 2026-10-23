import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/auth/domain/egypt_phone.dart';

void main() {
  group('normalizeEgyptMobile', () {
    test('accepts the formats people actually type', () {
      const expected = '+201012345678';
      for (final input in [
        '01012345678',
        '+201012345678',
        '00201012345678',
        '201012345678',
        '010 1234 5678',
        '010-1234-5678',
        '٠١٠١٢٣٤٥٦٧٨',
        '۰۱۰۱۲۳۴۵۶۷۸',
      ]) {
        expect(normalizeEgyptMobile(input), expected, reason: input);
      }
      expect(normalizeEgyptMobile('01512345678'), '+201512345678');
    });

    test('rejects invalid numbers', () {
      for (final input in [
        '',
        '0101234567',
        '010123456789',
        '01312345678',
        '0221234567',
        '+966512345678',
        'hello',
      ]) {
        expect(normalizeEgyptMobile(input), isNull, reason: input);
      }
    });
  });

  test('displayLocalPhone shows the local form', () {
    expect(displayLocalPhone('+201012345678'), '01012345678');
    expect(displayLocalPhone('01012345678'), '01012345678');
  });

  test('isolateLtr wraps text in isolate marks', () {
    expect(isolateLtr('010'), '\u2066010\u2069');
  });
}
