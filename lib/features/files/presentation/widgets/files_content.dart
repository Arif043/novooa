import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import '../../domain/entities/team_file.dart';
import 'delete_file_dialog.dart';
import 'file_tile.dart';
import '../pages/file_detail_page.dart';
import 'files_breadcrumbs.dart';
import 'folder_tile.dart';
import 'files_empty_state.dart';

class FilesContent extends StatelessWidget {
  const FilesContent({super.key, required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      FilesLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      FilesLoadStatus.failure => _FailureState(message: state.message),
      FilesLoadStatus.ready => _ReadyFilesContent(state: state),
    };
  }
}

class _ReadyFilesContent extends StatelessWidget {
  const _ReadyFilesContent({required this.state});

  final FilesState state;

  @override
  Widget build(BuildContext context) {
    final itemCount = state.visibleFolders.length + state.visibleFiles.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilesBreadcrumbs(state: state),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: itemCount == 0
              ? const FilesEmptyState()
              : Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: _FileList(state: state, itemCount: itemCount),
                ),
        ),
      ],
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.state, required this.itemCount});

  final FilesState state;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.read<FilesCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const Divider(
          height: AppSpacing.xs,
          indent: AppSpacing.md,
          endIndent: AppSpacing.md,
        ),
        itemBuilder: (context, index) => _itemFor(context, index),
      ),
    );
  }

  Widget _itemFor(BuildContext context, int index) {
    final folders = state.visibleFolders;
    if (index < folders.length) {
      final folder = folders[index];
      return FolderTile(
        folder: folder,
        onTap: () => context.read<FilesCubit>().openFolder(folder.id),
      );
    }
    final file = state.visibleFiles[index - folders.length];
    return FileTile(
      file: file,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => FileDetailPage(file: file)),
      ),
      onDelete: () => _confirmDelete(context, file),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Dateien konnten nicht geladen werden.'),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: context.read<FilesCubit>().load,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, TeamFile file) async {
  final confirmed = await DeleteFileDialog.show(context, file.displayName);
  if (confirmed != true || !context.mounted) return;
  await context.read<FilesCubit>().deleteFile(file.id);
}
