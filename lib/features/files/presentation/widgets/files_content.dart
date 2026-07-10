import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import 'file_tile.dart';
import 'files_breadcrumbs.dart';
import 'folder_tile.dart';

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
              ? const _EmptyState()
              : _FileList(state: state, itemCount: itemCount),
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
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
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
    return FileTile(file: state.visibleFiles[index - folders.length]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Dieses Verzeichnis ist leer.'));
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
