import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../cubits/file_detail_state.dart';
import 'file_detail_commands.dart';
import 'file_version_tile.dart';

/// Der Verlauf, neueste Version zuerst.
class FileVersionList extends StatelessWidget {
  const FileVersionList({
    super.key,
    required this.state,
    required this.commands,
  });

  final FileDetailReady state;
  final FileDetailCommands commands;

  @override
  Widget build(BuildContext context) {
    if (state.versions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: state.versions.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final version = state.versions[index];
        return FileVersionTile(
          version: version,
          isCurrent: state.isCurrent(version),
          isSelected: version.id == state.selectedVersionId,
          sizeDelta: state.sizeDeltaOf(version),
          onShow: () => commands.showVersion(version),
          onDownload: () => commands.download(version),
          onRestore: () => commands.restore(version),
        );
      },
    );
  }
}
