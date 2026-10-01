import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/event_trigger_config.dart';

/// Mehrfachauswahl der Dateikategorien. Keine Auswahl heißt: alle Dateien.
class EventFileKindChips extends StatelessWidget {
  const EventFileKindChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<EventFileKind> selected;
  final ValueChanged<Set<EventFileKind>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in EventFileKind.values)
          FilterChip(
            avatar: Icon(_iconFor(kind), size: AppSpacing.md),
            label: Text(kind.label),
            selected: selected.contains(kind),
            onSelected: (isSelected) => onChanged(_toggled(kind, isSelected)),
          ),
      ],
    );
  }

  Set<EventFileKind> _toggled(EventFileKind kind, bool isSelected) {
    return isSelected ? {...selected, kind} : ({...selected}..remove(kind));
  }

  IconData _iconFor(EventFileKind kind) {
    return switch (kind) {
      EventFileKind.text => CupertinoIcons.textformat,
      EventFileKind.image => CupertinoIcons.photo,
      EventFileKind.video => CupertinoIcons.videocam,
      EventFileKind.audio => CupertinoIcons.music_note,
      EventFileKind.pdf => CupertinoIcons.doc_richtext,
      EventFileKind.spreadsheet => CupertinoIcons.table,
      EventFileKind.other => CupertinoIcons.doc,
    };
  }
}
