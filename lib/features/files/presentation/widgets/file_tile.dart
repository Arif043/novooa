import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_file.dart';

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
      onTap: onTap,
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(
        file.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          '${_formatBytes(file.sizeBytes)} · ${file.contentType}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ),
      trailing: _FileMenu(fileName: file.displayName, onDelete: onDelete),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kib = bytes / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
    return '${(kib / 1024).toStringAsFixed(1)} MB';
  }
}

class _FileMenu extends StatelessWidget {
  const _FileMenu({required this.fileName, required this.onDelete});

  final String fileName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      tooltip: 'Aktionen für $fileName',
      itemBuilder: (_) => [
        PopupMenuItem<void>(
          onTap: onDelete,
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline),
            title: Text('Löschen'),
          ),
        ),
      ],
    );
  }
}
