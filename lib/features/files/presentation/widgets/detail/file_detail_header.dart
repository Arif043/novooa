import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/file_content_kind.dart';
import '../../../domain/entities/team_folder_tree.dart';
import '../../cubits/file_detail_state.dart';
import '../../localization/file_display_texts.dart';
import '../file_kind_badge.dart';
import 'file_detail_actions.dart';
import 'file_detail_commands.dart';

/// Zurück, Dateiart, Name, eine Zeile mit dem Wichtigsten und die Aktionen.
class FileDetailHeader extends StatelessWidget {
  const FileDetailHeader({
    super.key,
    required this.state,
    required this.commands,
    required this.compact,
  });

  final FileDetailReady state;
  final FileDetailCommands commands;

  /// Schmale Breite: alle Aktionen im Menü.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = const FileContentKindClassifier().classify(
      state.file.contentType,
      fileName: state.file.displayName,
    );
    return Row(
      children: [
        BackButton(onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: AppSpacing.xs),
        FileKindBadge(kind: kind),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  state.file.displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _meta(context, kind),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FileDetailActions(commands: commands, compact: compact),
      ],
    );
  }

  String _meta(BuildContext context, FileContentKind kind) {
    final texts = FileDisplayTexts.of(context);
    final file = state.file;
    final folderId = file.folderId;
    final folder = folderId == null
        ? null
        : folderPathLabel(folderId, state.folders);
    return [
      fileKindLabel(kind),
      texts.size(file.sizeBytes),
      LocaleKeys.files_meta_modified.tr(
        namedArgs: {'time': texts.relative(file.currentVersionCreatedAt)},
      ),
      if (folder != null)
        LocaleKeys.files_meta_in_folder.tr(namedArgs: {'folder': folder}),
    ].join(' · ');
  }
}
