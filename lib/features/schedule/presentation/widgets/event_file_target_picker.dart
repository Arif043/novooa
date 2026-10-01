import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../files/domain/entities/team_file.dart';
import '../../../files/domain/entities/team_folder.dart';
import '../../../files/domain/entities/team_folder_tree.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../cubits/event_target_options_state.dart';
import 'event_target_tile.dart';

enum _FileTargetMode { folder, file }

/// Zielwahl für Datei-Ereignisse: ein Verzeichnis (optional samt
/// Unterordnern) oder eine einzelne Datei.
class EventFileTargetPicker extends StatefulWidget {
  const EventFileTargetPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final EventTargetOptionsState options;
  final EventTriggerTarget selected;
  final ValueChanged<EventTriggerTarget> onChanged;

  @override
  State<EventFileTargetPicker> createState() => _EventFileTargetPickerState();
}

class _EventFileTargetPickerState extends State<EventFileTargetPicker> {
  late _FileTargetMode _mode = widget.selected is FileTarget
      ? _FileTargetMode.file
      : _FileTargetMode.folder;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_FileTargetMode>(
          segments: const [
            ButtonSegment(
              value: _FileTargetMode.folder,
              label: Text('Verzeichnis'),
            ),
            ButtonSegment(value: _FileTargetMode.file, label: Text('Datei')),
          ],
          selected: {_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.first),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _mode == _FileTargetMode.folder ? _folders() : _files(),
        ),
      ],
    );
  }

  Widget _folders() {
    final entries = flattenFolderTree(widget.options.folders);
    final selected = widget.selected;
    return ListView(
      children: [
        EventTargetTile(
          icon: Icons.all_inclusive,
          title: 'Überall',
          selected: selected is AnywhereTarget,
          onTap: () => widget.onChanged(EventTriggerTarget.anywhere),
        ),
        for (final entry in entries) _folderTile(entry, selected),
        if (selected is FolderTarget) _subfolderSwitch(selected),
      ],
    );
  }

  Widget _folderTile(FolderTreeEntry entry, EventTriggerTarget selected) {
    final folder = entry.folder;
    final isSelected = selected is FolderTarget && selected.id == folder.id;
    return EventTargetTile(
      icon: isSelected ? Icons.folder_open : Icons.folder_outlined,
      title: folder.name,
      depth: entry.depth + 1,
      selected: isSelected,
      onTap: () => widget.onChanged(_folderTarget(folder, selected)),
    );
  }

  FolderTarget _folderTarget(TeamFolder folder, EventTriggerTarget selected) {
    final keepSubfolders =
        selected is! FolderTarget || selected.includeSubfolders;
    return FolderTarget(
      id: folder.id,
      name: folderPathLabel(folder.id, widget.options.folders) ?? folder.name,
      includeSubfolders: keepSubfolders,
    );
  }

  Widget _subfolderSwitch(FolderTarget selected) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Unterordner einbeziehen'),
      value: selected.includeSubfolders,
      onChanged: (value) =>
          widget.onChanged(selected.copyWith(includeSubfolders: value)),
    );
  }

  Widget _files() {
    final files = _matchingFiles();
    final selected = widget.selected;
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Datei suchen',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text('Keine Datei gefunden.'))
              : ListView(
                  children: [
                    for (final file in files)
                      EventTargetTile(
                        icon: Icons.insert_drive_file_outlined,
                        title: file.displayName,
                        subtitle: _folderOf(file),
                        selected:
                            selected is FileTarget && selected.id == file.id,
                        onTap: () => widget.onChanged(
                          FileTarget(id: file.id, name: file.displayName),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  List<TeamFile> _matchingFiles() {
    final query = _query.toLowerCase();
    return widget.options.files
        .where((file) => file.displayName.toLowerCase().contains(query))
        .toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
  }

  String _folderOf(TeamFile file) {
    final folderId = file.folderId;
    if (folderId == null) return 'Oberste Ebene';
    return folderPathLabel(folderId, widget.options.folders) ?? 'Oberste Ebene';
  }
}
