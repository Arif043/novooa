import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/team_file.dart';

/// Meaningful fallback shown when no viewer exists for the file's content
/// type (e.g. pdf, audio, video, archives).
class UnsupportedContentView extends StatelessWidget {
  const UnsupportedContentView({super.key, required this.file});

  final TeamFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Semantics(
        label: 'Keine Vorschau verfügbar für ${file.displayName}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keine Vorschau für diesen Dateityp verfügbar.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              file.contentType,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
