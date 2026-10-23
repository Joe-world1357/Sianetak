import 'package:flutter/material.dart';

import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../app_scope.dart';

/// Language switch and account entry shown on every top-level screen.
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
          IconButton(
            tooltip: scope.auth.isSignedIn
                ? l10n.accountTooltip
                : l10n.signInTooltip,
            icon: Icon(
              scope.auth.isSignedIn ? Icons.account_circle : Icons.login,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => scope.auth.isSignedIn
                    ? const ProfileScreen()
                    : const SignInScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
