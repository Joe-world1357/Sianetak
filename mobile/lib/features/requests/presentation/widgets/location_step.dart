import 'package:flutter/material.dart';

import '../../../../core/device/location_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/auth_error_text.dart';
import '../../application/request_draft_controller.dart';
import 'draft_issue_text.dart';

/// Step 2: a saved address or a typed one, optionally with the device's current location
/// (FR-REQ-04). A map pin needs a maps provider, which is not integrated yet.
class LocationStep extends StatelessWidget {
  const LocationStep({
    super.key,
    required this.draft,
    required this.details,
    required this.landmark,
    required this.label,
    required this.showErrors,
    required this.locating,
    required this.locationFailure,
    required this.onUseCurrentLocation,
  });

  final RequestDraftController draft;
  final TextEditingController details;
  final TextEditingController landmark;
  final TextEditingController label;
  final bool showErrors;
  final bool locating;
  final LocationFailure? locationFailure;
  final VoidCallback onUseCurrentLocation;

  String _failureText(AppLocalizations l10n, LocationFailure f) => switch (f) {
    LocationFailure.denied => l10n.locationDenied,
    LocationFailure.deniedForever => l10n.locationDeniedForever,
    LocationFailure.serviceDisabled => l10n.locationServiceOff,
    LocationFailure.unavailable => l10n.locationUnavailable,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final issue = showErrors ? draft.locationIssue() : null;
    final areas = draft.options.areas;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (draft.savedAddresses.isNotEmpty) ...[
          Semantics(
            header: true,
            child: Text(
              l10n.savedAddressesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          RadioGroup<String>(
            groupValue: draft.useNewAddress ? '' : draft.selectedAddressId,
            onChanged: (v) {
              if (v == null) return;
              if (v.isEmpty) {
                draft.useTypedAddress();
              } else {
                draft.selectSavedAddress(v);
              }
            },
            child: Column(
              children: [
                for (final a in draft.savedAddresses)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: a.id,
                    title: Text(a.label ?? a.area.name.resolve(lang)),
                    subtitle: Text(
                      '${a.area.name.resolve(lang)} — ${a.details}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: '',
                  title: Text(l10n.newAddressOption),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (draft.useNewAddress) ...[
          if (areas.isEmpty)
            AuthErrorText(l10n.noAreasConfigured)
          else
            DropdownButtonFormField<String>(
              initialValue: draft.areaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.areaLabel,
                errorText: issue == DraftIssue.areaMissing
                    ? l10n.areaRequired
                    : null,
              ),
              items: [
                for (final a in areas)
                  DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name.resolve(lang)),
                  ),
              ],
              onChanged: (v) => draft.update(() => draft.areaId = v),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: details,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            onChanged: (v) => draft.update(() => draft.details = v),
            decoration: InputDecoration(
              labelText: l10n.addressDetailsLabel,
              hintText: l10n.addressDetailsHint,
              alignLabelWithHint: true,
              errorText: issue == DraftIssue.detailsTooShort
                  ? draftIssueMessage(l10n, issue!, draft.options)
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: landmark,
            maxLength: 150,
            onChanged: (v) => draft.update(() => draft.landmark = v),
            decoration: InputDecoration(labelText: l10n.landmarkLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CurrentLocation(
            draft: draft,
            locating: locating,
            failure: locationFailure == null
                ? null
                : _failureText(l10n, locationFailure!),
            onUse: onUseCurrentLocation,
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: draft.saveAddress,
            onChanged: (v) =>
                draft.update(() => draft.saveAddress = v ?? false),
            title: Text(l10n.saveAddressLabel),
          ),
          if (draft.saveAddress)
            TextField(
              controller: label,
              maxLength: 40,
              onChanged: (v) => draft.update(() => draft.label = v),
              decoration: InputDecoration(
                labelText: l10n.addressLabelLabel,
                hintText: l10n.addressLabelHint,
              ),
            ),
        ],
        if (issue == DraftIssue.addressMissing)
          AuthErrorText(l10n.addressMissing),
      ],
    );
  }
}

class _CurrentLocation extends StatelessWidget {
  const _CurrentLocation({
    required this.draft,
    required this.locating,
    required this.failure,
    required this.onUse,
  });

  final RequestDraftController draft;
  final bool locating;
  final String? failure;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (draft.point == null)
              OutlinedButton.icon(
                onPressed: locating ? null : onUse,
                icon: locating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(locating ? l10n.locating : l10n.useCurrentLocation),
              )
            else
              Row(
                children: [
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(l10n.locationCaptured),
                    ),
                  ),
                  TextButton(
                    onPressed: () => draft.update(() => draft.point = null),
                    child: Text(l10n.locationRemove),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.locationOptionalNote, style: theme.textTheme.bodySmall),
            if (failure != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AuthErrorText(failure!),
            ],
          ],
        ),
      ),
    );
  }
}
