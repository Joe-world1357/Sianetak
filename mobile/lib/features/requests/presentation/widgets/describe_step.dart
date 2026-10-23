import 'package:flutter/material.dart';

import '../../../../core/device/image_picker_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/auth_error_text.dart';
import '../../application/request_draft_controller.dart';
import 'draft_issue_text.dart';
import 'photo_tile.dart';

/// Step 1: problem description and optional photos (FR-REQ-02, FR-REQ-03).
class DescribeStep extends StatelessWidget {
  const DescribeStep({
    super.key,
    required this.draft,
    required this.description,
    required this.showErrors,
    required this.onPick,
    this.pickError,
  });

  final RequestDraftController draft;
  final TextEditingController description;
  final bool showErrors;
  final void Function(ImageOrigin origin) onPick;
  final String? pickError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final options = draft.options;
    final descriptionIssue = showErrors ? draft.descriptionIssue() : null;
    final photosIssue = showErrors ? draft.photosIssue() : null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TextField(
          controller: description,
          minLines: 4,
          maxLines: 8,
          maxLength: options.descriptionMaxLength,
          textInputAction: TextInputAction.newline,
          onChanged: (v) => draft.update(() => draft.description = v),
          decoration: InputDecoration(
            labelText: l10n.descriptionLabel,
            hintText: l10n.descriptionHint,
            alignLabelWithHint: true,
            errorText: descriptionIssue == null
                ? null
                : draftIssueMessage(l10n, descriptionIssue, options),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(
            l10n.photosTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (!options.uploadsAvailable)
          Text(l10n.photoUploadsUnavailable, style: theme.textTheme.bodyMedium)
        else ...[
          Text(
            l10n.photosHelp(options.maxPhotos),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (i, photo) in draft.photos.indexed)
                PhotoTile(
                  key: ValueKey(photo.localId),
                  photo: photo,
                  index: i,
                  onRetry: () => draft.retryPhoto(photo.localId),
                  onRemove: () => draft.removePhoto(photo.localId),
                ),
            ],
          ),
          if (draft.photos.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          if (draft.canAddPhoto)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageOrigin.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.addPhotoCamera),
                ),
                OutlinedButton.icon(
                  onPressed: () => onPick(ImageOrigin.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.addPhotoGallery),
                ),
              ],
            )
          else
            Text(
              l10n.photoLimitReached(options.maxPhotos),
              style: theme.textTheme.bodySmall,
            ),
        ],
        if (pickError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AuthErrorText(pickError!),
        ],
        if (photosIssue != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AuthErrorText(draftIssueMessage(l10n, photosIssue, options)),
        ],
      ],
    );
  }
}
