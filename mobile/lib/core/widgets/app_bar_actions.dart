import 'package:flutter/material.dart';

import '../../features/auth/presentation/sign_in_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../app_scope.dart';

/// Language switch, plus sign-in for guests. Signed-in users reach their account from the
/// bottom navigation.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.auth,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: scope.locale.toggle,
            child: Semantics(
              label: l10n.switchLanguageTooltip,
              excludeSemantics: true,
              child: Text(l10n.switchLanguage),
            ),
          ),
          if (!scope.auth.isSignedIn)
            IconButton(
              tooltip: l10n.signInTooltip,
              icon: const Icon(Icons.login),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
