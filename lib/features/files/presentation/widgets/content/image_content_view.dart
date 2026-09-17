import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/team_file.dart';

/// Renders image bytes with pan/zoom support.
class ImageContentView extends StatelessWidget {
  const ImageContentView({super.key, required this.file, required this.bytes});

  final TeamFile file;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        maxScale: 4,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          semanticLabel: 'Vorschau von ${file.displayName}',
          errorBuilder: (context, error, stackTrace) =>
              const _ImageLoadError(),
        ),
      ),
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text('Bild konnte nicht geladen werden.'),
      ],
    );
  }
}
