import 'package:flutter/material.dart';

import '../../domain/entities/team_folder.dart';
import '../../../../core/theme/app_spacing.dart';
import 'file_kind_badge.dart';

class FolderTile extends StatelessWidget {
  const FolderTile({super.key, required this.folder, required this.onTap});

  final TeamFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: const FileKindBadge(isFolder: true),
      subtitle: const Text('Ordner'),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
