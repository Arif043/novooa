import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/files/domain/entities/file_content_kind.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';

/// Dateikategorien, nach denen bestehende Dateien in der Zielwahl gefiltert
/// werden. `all` ist der neutrale Zustand ohne Einschränkung.
enum WriteFileKindFilter {
  all('Alle', CupertinoIcons.square_grid_2x2),
  text('Text', CupertinoIcons.textformat),
  image('Bilder', CupertinoIcons.photo),
  video('Video', CupertinoIcons.videocam),
  audio('Audio', CupertinoIcons.music_note),
  pdf('PDF', CupertinoIcons.doc_richtext),
  spreadsheet('Tabellen', CupertinoIcons.table);

  const WriteFileKindFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool matches(NodeAttachment file) {
    return switch (this) {
      all => true,
      video => file.contentType.startsWith('video/'),
      audio => file.contentType.startsWith('audio/'),
      _ => _classifiedKind(file) == _contentKind,
    };
  }

  FileContentKind get _contentKind => switch (this) {
    text => FileContentKind.text,
    image => FileContentKind.image,
    pdf => FileContentKind.pdf,
    _ => FileContentKind.spreadsheet,
  };

  static FileContentKind _classifiedKind(NodeAttachment file) {
    return const FileContentKindClassifier().classify(
      file.contentType,
      fileName: file.displayName,
    );
  }

  /// `Alle` plus nur die Kategorien, zu denen es Dateien gibt — leere Chips
  /// würden nur in eine leere Liste führen.
  static List<WriteFileKindFilter> availableFor(List<NodeAttachment> files) {
    return [
      for (final filter in values)
        if (filter == all || files.any(filter.matches)) filter,
    ];
  }
}

class WriteFileKindFilterChips extends StatelessWidget {
  const WriteFileKindFilterChips({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<WriteFileKindFilter> filters;
  final WriteFileKindFilter selected;
  final ValueChanged<WriteFileKindFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final filter in filters)
          ChoiceChip(
            avatar: Icon(filter.icon, size: AppSpacing.md),
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onSelected(filter),
          ),
      ],
    );
  }
}
