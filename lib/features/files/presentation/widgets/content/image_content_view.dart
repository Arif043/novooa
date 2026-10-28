import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

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
          semanticLabel: LocaleKeys.files_preview_of.tr(
            namedArgs: {'name': file.displayName},
          ),
          errorBuilder: (context, error, stackTrace) => const _ImageLoadError(),
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
        Text(LocaleKeys.files_image_load_failed.tr()),
      ],
    );
  }
}
