import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../app_scope.dart';

/// An image stored privately on the server, fetched with the signed-in user's credentials.
/// Bytes stay in memory only; nothing is cached to disk.
class PrivateImage extends StatefulWidget {
  const PrivateImage({
    super.key,
    required this.mediaId,
    required this.semanticLabel,
    this.fit = BoxFit.cover,
  });

  final String mediaId;
  final String semanticLabel;
  final BoxFit fit;

  @override
  State<PrivateImage> createState() => _PrivateImageState();
}

class _PrivateImageState extends State<PrivateImage> {
  Future<Uint8List>? _bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bytes ??= AppScope.of(context).media.fetch(widget.mediaId);
  }

  void _retry() {
    setState(() {
      _bytes = AppScope.of(context).media.fetch(widget.mediaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Material(
            color: scheme.surfaceContainerHighest,
            child: InkWell(
              onTap: _retry,
              child: Center(
                child: Tooltip(
                  message: l10n.photoLoadFailed,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: scheme.outline,
                  ),
                ),
              ),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          semanticLabel: widget.semanticLabel,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) =>
              Icon(Icons.broken_image_outlined, color: scheme.outline),
        );
      },
    );
  }
}
