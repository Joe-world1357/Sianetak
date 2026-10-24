import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Signs in through the demo account picker (the first, and with fakes only, account).
Future<void> signIn(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.login));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.chevron_right).first);
  await tester.pumpAndSettle();
  await dismissSnackBars(tester);
}

/// Snack bars sit over bottom buttons; clear them before tapping there.
Future<void> dismissSnackBars(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
      .removeCurrentSnackBar();
  await tester.pumpAndSettle();
}

/// Opens the Account tab of the signed-in navigation.
Future<void> openProfile(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.person_outline_rounded));
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view (building it first if needed), then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await showVisible(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view, building it first if a lazy list has not yet.
Future<void> showVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // Not built yet: lazy lists only build what is near the viewport.
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> scrollToTop(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await tester.pumpAndSettle();
}
