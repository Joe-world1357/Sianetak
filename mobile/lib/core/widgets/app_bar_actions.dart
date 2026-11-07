import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_scope.dart';

/// Language switch for app bars. Accounts are reached from the bottom navigation.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: TextButton(
        onPressed: scope.locale.toggle,
        child: Semantics(
          label: l10n.switchLanguageTooltip,
          excludeSemantics: true,
          child: Text(l10n.switchLanguage),
        ),
      ),
    );
  }
}
