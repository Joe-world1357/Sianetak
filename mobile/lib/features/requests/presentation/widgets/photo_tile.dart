import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/request_draft_controller.dart';

/// Thumbnail of a picked photo with its upload state, retry and remove actions.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.photo,
    required this.index,
    required this.onRetry,
    required this.onRemove,
  });

  static const size = 104.0;

  final PhotoAttachment photo;
  final int index;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = switch (photo.status) {
      PhotoStatus.uploading => l10n.photoUploading,
      PhotoStatus.failed => l10n.photoFailed,
      PhotoStatus.uploaded => null,
    };
    return Semantics(
      label: [l10n.photoNumber(index + 1), ?state].join('، '),
      child: SizedBox.square(
        dimension: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Image.memory(photo.file.bytes, fit: BoxFit.cover),
              ),
              if (photo.status == PhotoStatus.uploading)
                const ColoredBox(
                  color: Color(0x88000000),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
              if (photo.status == PhotoStatus.failed)
                ColoredBox(
                  color: scheme.error.withValues(alpha: 0.75),
                  child: Center(
                    child: IconButton(
                      tooltip: l10n.photoRetry,
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  tooltip: l10n.photoRemove,
                  onPressed: onRemove,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xAA000000),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.square(32),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
