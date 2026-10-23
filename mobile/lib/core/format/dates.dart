import 'package:intl/intl.dart';

String _locale(String languageCode) => languageCode == 'ar' ? 'ar_EG' : 'en';

/// Dates and times are shown in the device's local time (the Aswan launch market is
/// Africa/Cairo); the API always exchanges UTC instants.
String formatDay(DateTime instant, String languageCode) =>
    DateFormat('EEEE d MMMM', _locale(languageCode)).format(instant.toLocal());

String formatTime(DateTime instant, String languageCode) =>
    DateFormat.jm(_locale(languageCode)).format(instant.toLocal());

String formatDateTime(DateTime instant, String languageCode) =>
    DateFormat.yMMMd(_locale(languageCode)).add_jm().format(instant.toLocal());

/// True when both instants fall on the same local calendar day.
bool sameLocalDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year == y.year && x.month == y.month && x.day == y.day;
}
