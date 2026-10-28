import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_folder.dart';
import '../../domain/entities/team_folder_tree.dart';

/// Auswahl eines Verzeichnisses als eingerückter Baum, beginnend mit der
/// obersten Ebene (`null`).
class TeamFolderChoiceList extends StatelessWidget {
  const TeamFolderChoiceList({
    super.key,
    required this.folders,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final List<TeamFolder> folders;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FolderTile(
          label: LocaleKeys.ui_oberste_ebene.tr(),
          depth: 0,
          selected: selectedFolderId == null,
          onTap: () => onSelected(null),
        ),
        for (final entry in flattenFolderTree(folders))
          _FolderTile(
            label: entry.folder.name,
            depth: entry.depth + 1,
            selected: entry.folder.id == selectedFolderId,
            onTap: () => onSelected(entry.folder.id),
          ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.label,
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: LocaleKeys.ui_directory_named.tr(namedArgs: {'name': label}),
      child: ListTile(
        dense: true,
        minTileHeight: 48,
        contentPadding: EdgeInsets.only(left: depth * AppSpacing.md),
        leading: Icon(
          selected ? Icons.folder_open : Icons.folder_outlined,
          color: selected ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(label, overflow: TextOverflow.ellipsis),
        trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
