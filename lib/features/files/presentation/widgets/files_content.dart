import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/layout/page_insets.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/team_file.dart';
import '../cubits/files_cubit.dart';
import '../cubits/files_state.dart';
import '../pages/file_detail_page.dart';
import 'delete_file_dialog.dart';
import 'file_tile.dart';
import 'files_empty_state.dart';
import 'files_item_card.dart';
import 'folder_tile.dart';

/// Inhalt unterhalb der Kopfzeile als Slivers: Laden, Fehler, leerer Ordner
/// oder die Liste der Ordner und Dateien.
class FilesContent {
  const FilesContent({required this.state, required this.insets});

  final FilesState state;
  final PageInsets insets;

  List<Widget> slivers() {
    return switch (state.status) {
      FilesLoadStatus.loading => [
        _fill(const Center(child: CircularProgressIndicator())),
      ],
      FilesLoadStatus.failure => [_fill(_FailureState(message: state.message))],
      FilesLoadStatus.ready => _ready(),
    };
  }

  List<Widget> _ready() {
    final itemCount = state.visibleFolders.length + state.visibleFiles.length;
    if (itemCount == 0) return [_fill(const FilesEmptyState())];
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(insets.inset, 0, insets.inset, 40),
        sliver: SliverList.separated(
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              FilesItemCard(child: _itemFor(context, index)),
        ),
      ),
    ];
  }

  Widget _fill(Widget child) => SliverFillRemaining(
    hasScrollBody: false,
    child: Padding(padding: EdgeInsets.all(insets.gutter), child: child),
  );

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
      onTap: () => Navigator.of(context).push(FileDetailPage.route(file)),
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
