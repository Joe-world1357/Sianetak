import 'package:intl/intl.dart';

/// Formats integer minor units (piastres) as Egyptian pounds for the given language.
/// Amounts are never handled as floating point beyond this display step.
String formatEgp(int minorUnits, String languageCode) {
  final pounds = minorUnits ~/ 100;
  final piastres = minorUnits % 100;
  final isArabic = languageCode == 'ar';
  final number = NumberFormat.decimalPattern(isArabic ? 'ar_EG' : 'en');
  final whole = number.format(pounds);
  final amount = piastres == 0
      ? whole
      : '$whole${number.symbols.DECIMAL_SEP}${number.format(piastres).padLeft(2, number.format(0))}';
  return isArabic ? '$amount ج.م' : 'EGP $amount';
}

/// Whole numbers in the UI language's digits, matching how amounts are shown.
String formatCount(int value, String languageCode) =>
    NumberFormat.decimalPattern(languageCode == 'ar' ? 'ar_EG' : 'en')
        .format(value);
