import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/team_file.dart';

/// Leerer Zustand, wenn es für den Dateityp keine Vorschau gibt; die
/// Handlung ist das Herunterladen.
class UnsupportedContentView extends StatelessWidget {
  const UnsupportedContentView({
    super.key,
    required this.file,
    required this.onDownload,
  });

  final TeamFile file;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: AppSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
              semanticLabel: LocaleKeys.files_no_preview_for.tr(
                namedArgs: {'name': file.displayName},
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.files_unsupported_hint.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(Icons.download_outlined),
              label: Text(LocaleKeys.files_action_download.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
