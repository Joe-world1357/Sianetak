import '../../../../l10n/generated/app_localizations.dart';
import '../../application/request_draft_controller.dart';
import '../../domain/request_models.dart';

String draftIssueMessage(
  AppLocalizations l10n,
  DraftIssue issue,
  RequestOptions options,
) => switch (issue) {
  DraftIssue.descriptionTooShort => l10n.descriptionTooShort(
    options.descriptionMinLength,
  ),
  DraftIssue.descriptionTooLong => l10n.descriptionTooLong(
    options.descriptionMaxLength,
  ),
  DraftIssue.photosUploading => l10n.photosUploadingWait,
  DraftIssue.photosFailed => l10n.photosFailedFix,
  DraftIssue.addressMissing => l10n.addressMissing,
  DraftIssue.areaMissing => l10n.areaRequired,
  DraftIssue.detailsTooShort => l10n.addressDetailsTooShort,
  DraftIssue.scheduleMissing => l10n.scheduleMissing,
};
