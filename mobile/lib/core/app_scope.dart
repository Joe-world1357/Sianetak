import 'package:flutter/widgets.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/catalog/data/catalog_repository.dart';
import 'locale/locale_controller.dart';

/// Dependency container for the widget tree; swapped for fakes in tests.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.catalog,
    required this.auth,
    required this.locale,
    required super.child,
  });

  final CatalogRepository catalog;
  final AuthController auth;
  final LocaleController locale;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing from the widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      catalog != oldWidget.catalog ||
      auth != oldWidget.auth ||
      locale != oldWidget.locale;
}
