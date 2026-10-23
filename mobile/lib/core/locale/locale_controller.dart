import 'package:flutter/widgets.dart';

/// Current UI language. Arabic is the default (NFR-UX-01); English is available.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale initial = arabic}) : _locale = initial;

  static const arabic = Locale('ar');
  static const english = Locale('en');
  static const supported = [arabic, english];

  Locale _locale;
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  void toggle() {
    _locale = isArabic ? english : arabic;
    notifyListeners();
  }
}
