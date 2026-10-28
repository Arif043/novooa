import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import 'file_detail_commands.dart';

typedef _Action = ({IconData icon, String label, Future<void> Function()? run});

/// Häufige Aktionen als Symbolknöpfe, seltene und die destruktive im Menü;
/// auf dem Handy alles im Menü.
class FileDetailActions extends StatelessWidget {
  const FileDetailActions({
    super.key,
    required this.commands,
    required this.compact,
  });

  final FileDetailCommands commands;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final primary = _primaryActions;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact)
          for (final action in primary)
            IconButton(
              tooltip: action.label,
              onPressed: action.run,
              icon: Icon(action.icon),
            ),
        _MoreMenu(
          actions: [if (compact) ...primary, ..._secondaryActions],
          onDelete: commands.delete,
        ),
      ],
    );
  }

  List<_Action> get _primaryActions => [
    (
      icon: Icons.drive_file_rename_outline,
      label: LocaleKeys.files_action_rename.tr(),
      run: commands.rename,
    ),
    (
      icon: Icons.download_outlined,
      label: LocaleKeys.files_action_download.tr(),
      run: commands.download,
    ),
    if (commands.isImage)
      (
        icon: Icons.auto_fix_high_outlined,
        label: commands.canEditImage
            ? LocaleKeys.files_action_edit_image.tr()
            : LocaleKeys.files_action_edit_image_unsupported.tr(),
        run: commands.canEditImage ? commands.editImage : null,
      ),
    (
      icon: Icons.copy_outlined,
      label: LocaleKeys.files_action_copy.tr(),
      run: commands.copy,
    ),
  ];

  List<_Action> get _secondaryActions => [
    (
      icon: Icons.drive_file_move_outline,
      label: LocaleKeys.files_action_move.tr(),
      run: commands.move,
    ),
    (
      icon: Icons.upload_file_outlined,
      label: LocaleKeys.files_action_upload_version.tr(),
      run: commands.uploadVersion,
    ),
  ];
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.actions, required this.onDelete});

  final List<_Action> actions;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    return MenuAnchor(
      menuChildren: [
        for (final action in actions)
          MenuItemButton(
            leadingIcon: Icon(action.icon),
            onPressed: action.run,
            child: Text(action.label),
          ),
        const Divider(),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_outline, color: error),
          onPressed: onDelete,
          child: Text(
            LocaleKeys.files_action_delete.tr(),
            style: TextStyle(color: error),
          ),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        tooltip: LocaleKeys.files_more_actions.tr(),
        icon: const Icon(Icons.more_vert),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
