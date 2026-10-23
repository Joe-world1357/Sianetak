/// Egyptian mobile number handling; mirrors the backend rules (backend/src/common/phone).
/// The server remains the authority — this only gives instant feedback while typing.
library;

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const _extendedArabicIndic = '۰۱۲۳۴۵۶۷۸۹';

/// Converts Arabic-Indic and Persian digits to ASCII digits.
String toAsciiDigits(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    var index = _arabicIndic.indexOf(ch);
    if (index < 0) index = _extendedArabicIndic.indexOf(ch);
    buffer.write(index >= 0 ? index.toString() : ch);
  }
  return buffer.toString();
}

final _e164EgyptMobile = RegExp(r'^\+201[0125]\d{8}$');

/// Returns `+201XXXXXXXXX`, or null if [input] is not a valid Egyptian mobile number.
String? normalizeEgyptMobile(String input) {
  var s = toAsciiDigits(input).replaceAll(RegExp(r'[\s\-().]'), '');
  if (s.startsWith('00')) s = '+${s.substring(2)}';
  if (s.startsWith('20') && s.length == 12) s = '+$s';
  if (s.startsWith('01') && s.length == 11) s = '+2$s';
  return _e164EgyptMobile.hasMatch(s) ? s : null;
}

/// Local display form: `+201012345678` → `01012345678`.
String displayLocalPhone(String e164) =>
    e164.startsWith('+20') ? '0${e164.substring(3)}' : e164;

/// Wraps [text] in Unicode isolate marks so a Latin-digit number inside Arabic text
/// keeps its left-to-right order (U+2066 … U+2069).
String isolateLtr(String text) => '\u2066$text\u2069';
