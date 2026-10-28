import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/file_content_kind.dart';
import '../../../domain/entities/team_folder_tree.dart';
import '../../cubits/file_detail_state.dart';
import '../../localization/file_display_texts.dart';
import '../file_kind_badge.dart';

/// Eigenschaften der Datei als Liste aus Bezeichnung und Wert.
class FileDetailsPanel extends StatelessWidget {
  const FileDetailsPanel({super.key, required this.state});

  final FileDetailReady state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final (label, value) in _entries(context))
          _DetailEntry(label: label, value: value),
      ],
    );
  }

  List<(String, String)> _entries(BuildContext context) {
    final texts = FileDisplayTexts.of(context);
    final file = state.file;
    final kind = const FileContentKindClassifier().classify(
      file.contentType,
      fileName: file.displayName,
    );
    return [
      (LocaleKeys.files_detail_type.tr(), fileKindLabel(kind)),
      (LocaleKeys.files_detail_format.tr(), file.contentType),
      (LocaleKeys.files_detail_size.tr(), texts.size(file.sizeBytes)),
      (LocaleKeys.files_detail_folder.tr(), _folder()),
      (LocaleKeys.files_detail_created.tr(), texts.dateTime(file.createdAt)),
      (
        LocaleKeys.files_detail_modified.tr(),
        texts.dateTime(file.currentVersionCreatedAt),
      ),
      (LocaleKeys.files_detail_versions.tr(), _versions()),
    ];
  }

  String _folder() {
    final folderId = state.file.folderId;
    if (folderId == null) return LocaleKeys.ui_oberste_ebene.tr();
    return folderPathLabel(folderId, state.folders) ??
        LocaleKeys.ui_oberste_ebene.tr();
  }

  String _versions() {
    final count = '${state.versions.length}';
    final limit = state.versionLimit;
    if (limit == null) return count;
    return LocaleKeys.files_detail_versions_value.tr(
      namedArgs: {'count': count, 'limit': '$limit'},
    );
  }
}

class _DetailEntry extends StatelessWidget {
  const _DetailEntry({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs / 2),
            SelectableText(value, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
