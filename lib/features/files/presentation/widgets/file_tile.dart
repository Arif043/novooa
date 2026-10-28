import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/widgets/ios_context_menu.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_file.dart';
import '../../domain/entities/file_content_kind.dart';
import '../localization/file_display_texts.dart';
import 'file_kind_badge.dart';

class FileTile extends StatelessWidget {
  const FileTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  final TeamFile file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      leading: FileKindBadge(kind: _kind),
      title: Text(
        file.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          '${fileKindLabel(_kind)} · ${FileDisplayTexts.of(context).size(file.sizeBytes)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ),
      trailing: _FileMenu(fileName: file.displayName, onDelete: onDelete),
    );
  }

  FileContentKind get _kind => const FileContentKindClassifier().classify(
    file.contentType,
    fileName: file.displayName,
  );
}

class _FileMenu extends StatelessWidget {
  const _FileMenu({required this.fileName, required this.onDelete});

  final String fileName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return IosContextMenuButton<VoidCallback>(
      tooltip: LocaleKeys.files_actions_for.tr(namedArgs: {'name': fileName}),
      entries: [
        IosContextMenuItem(
          value: onDelete,
          icon: Icons.delete_outline,
          label: LocaleKeys.files_action_delete.tr(),
          isDestructive: true,
        ),
      ],
      onSelected: (run) => run(),
    );
  }
}
