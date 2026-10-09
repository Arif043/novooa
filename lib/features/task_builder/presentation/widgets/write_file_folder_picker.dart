import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/write_file_folders_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/write_file_folders_state.dart';
import 'package:syscat2/features/files/domain/entities/team_folder_tree.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/write_file_new_folder_row.dart';

/// Zielverzeichnis für eine neue Datei: oberste Ebene oder ein bestehendes
/// Verzeichnis. Neue Verzeichnisse entstehen im gerade gewählten.
class WriteFileFolderPicker extends StatelessWidget {
  const WriteFileFolderPicker({
    super.key,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(LocaleKeys.ui_verzeichnis.tr(), style: textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        BlocBuilder<WriteFileFoldersCubit, WriteFileFoldersState>(
          builder: (context, state) => _content(context, state),
        ),
      ],
    );
  }

  Widget _content(BuildContext context, WriteFileFoldersState state) {
    return switch (state.status) {
      WriteFileFoldersStatus.loading => const LinearProgressIndicator(),
      WriteFileFoldersStatus.failure => _FolderError(
        message: state.message ?? LocaleKeys.ui_folders_load_failed.tr(),
      ),
      WriteFileFoldersStatus.ready => _FolderChoices(
        state: state,
        selectedFolderId: selectedFolderId,
        onSelected: onSelected,
      ),
    };
  }
}

class _FolderChoices extends StatelessWidget {
  const _FolderChoices({
    required this.state,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final WriteFileFoldersState state;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final entries = flattenFolderTree(state.folders);
    final parentLabel = selectedFolderId == null
        ? null
        : folderPathLabel(selectedFolderId!, state.folders);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _FolderTile(
                  label: LocaleKeys.ui_oberste_ebene.tr(),
                  depth: 0,
                  selected: selectedFolderId == null,
                  onTap: () => onSelected(null),
                ),
                for (final entry in entries)
                  _FolderTile(
                    label: entry.folder.name,
                    depth: entry.depth + 1,
                    selected: entry.folder.id == selectedFolderId,
                    onTap: () => onSelected(entry.folder.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        WriteFileNewFolderRow(
          parentLabel: parentLabel,
          isCreating: state.isCreating,
          errorMessage: state.message,
          onCreate: (name) => _create(context, name),
        ),
      ],
    );
  }

  Future<bool> _create(BuildContext context, String name) async {
    final folderId = await context.read<WriteFileFoldersCubit>().createFolder(
      name: name,
      parentFolderId: selectedFolderId,
    );
    if (folderId == null) return false;
    onSelected(folderId);
    return true;
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

class _FolderError extends StatelessWidget {
  const _FolderError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(
          onPressed: context.read<WriteFileFoldersCubit>().load,
          child: Text(LocaleKeys.ui_erneut_versuchen.tr()),
        ),
      ],
    );
  }
}
