import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/file_content_kind.dart';

class FileKindBadge extends StatelessWidget {
  const FileKindBadge({super.key, this.kind, this.isFolder = false});

  final FileContentKind? kind;
  final bool isFolder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: ShapeDecoration(
          color: isFolder
              ? colors.primaryContainer
              : colors.surfaceContainerLow,
          shape:
              Theme.of(context).inputDecorationTheme.enabledBorder ??
              const RoundedRectangleBorder(),
        ),
        child: Icon(
          _icon,
          color: isFolder ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        ),
      ),
    );
  }

  IconData get _icon => isFolder
      ? Icons.folder_outlined
      : switch (kind) {
          FileContentKind.pdf => Icons.picture_as_pdf_outlined,
          FileContentKind.image => Icons.image_outlined,
          FileContentKind.text => Icons.description_outlined,
          FileContentKind.spreadsheet => Icons.table_chart_outlined,
          _ => Icons.insert_drive_file_outlined,
        };
}

String fileKindLabel(FileContentKind kind) => switch (kind) {
  FileContentKind.pdf => 'PDF-Dokument',
  FileContentKind.image => 'Bild',
  FileContentKind.text => 'Textdokument',
  FileContentKind.spreadsheet => 'Tabelle',
  FileContentKind.unsupported => 'Datei',
};
