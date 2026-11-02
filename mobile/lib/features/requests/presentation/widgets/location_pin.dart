import 'package:flutter/material.dart';

import '../../../../core/app_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/egypt_phone.dart';
import '../../domain/request_models.dart';

/// A request's location pin: its coordinates and a button that shows it in the phone's
/// maps app (FR-REQ-04). The app itself has no map, because it works offline.
class LocationPin extends StatelessWidget {
  const LocationPin({super.key, required this.point, this.label});

  final GeoPoint point;

  /// Shown as the pin's name in the maps app, when it supports one.
  final String? label;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await AppScope.of(context).maps.open(point, label: label);
    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.mapsUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.location_on_rounded, color: AppColors.success.$1),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locationPinTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
              // Coordinates read left-to-right, also in Arabic.
              Text(
                isolateLtr(point.display),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => _open(context),
          icon: const Icon(Icons.map_outlined),
          label: Text(l10n.openInMaps),
        ),
      ],
    );
  }
}
