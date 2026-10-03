import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'file_kind_badge.dart';

class FilesEmptyState extends StatelessWidget {
  const FilesEmptyState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FileKindBadge(isFolder: true),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Platz für deine Dateien',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Lade über „Datei hochladen“ dein erstes Dokument hoch '
            'oder lege mit „Neuer Ordner“ eine Struktur an.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
