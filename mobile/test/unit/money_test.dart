import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sianetak_customer/core/format/money.dart';

void main() {
  setUpAll(initializeDateFormatting);

  test('formats whole pounds in English', () {
    expect(formatEgp(15000, 'en'), 'EGP 150');
    expect(formatEgp(123456700, 'en'), 'EGP 1,234,567');
  });

  test('includes piastres only when non-zero', () {
    expect(formatEgp(15050, 'en'), 'EGP 150.50');
    expect(formatEgp(15005, 'en'), 'EGP 150.05');
  });

  test('formats Arabic amounts with the EGP suffix', () {
    final arabic = formatEgp(15000, 'ar');
    expect(arabic, endsWith('ج.م'));
    expect(arabic, contains('١٥٠'));
  });
}
