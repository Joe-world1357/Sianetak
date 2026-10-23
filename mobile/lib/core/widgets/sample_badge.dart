import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Marks catalog entries that are placeholder data, not approved by operations.
class SampleBadge extends StatelessWidget {
  const SampleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.sampleDataNotice,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.sampleBadgeBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l10n.sampleDataBadge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.sampleBadge,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
