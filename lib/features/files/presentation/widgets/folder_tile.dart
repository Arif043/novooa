import 'package:flutter/material.dart';

import '../../domain/entities/team_folder.dart';

class FolderTile extends StatelessWidget {
  const FolderTile({super.key, required this.folder, required this.onTap});

  final TeamFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(folder.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
