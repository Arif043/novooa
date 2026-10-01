import 'package:flutter/cupertino.dart';

import '../../../../core/theme/output_type_colors.dart';
import '../../domain/entities/task_execution_result.dart';

/// Einzige Quelle für Farbe, Icon und Klartextname eines [NodeOutputType]
/// in der UI. Die Farben stammen aus [OutputTypeColors].
class NodeOutputTypeStyle {
  const NodeOutputTypeStyle._(this.color, this.icon, this.label);

  final Color color;
  final IconData icon;
  final String label;

  static NodeOutputTypeStyle of(NodeOutputType type) {
    return switch (type) {
      NodeOutputType.string => const NodeOutputTypeStyle._(
        OutputTypeColors.string,
        CupertinoIcons.textformat,
        'Text',
      ),
      NodeOutputType.datetime => const NodeOutputTypeStyle._(
        OutputTypeColors.datetime,
        CupertinoIcons.calendar,
        'Datum und Uhrzeit',
      ),
      NodeOutputType.number => const NodeOutputTypeStyle._(
        OutputTypeColors.number,
        CupertinoIcons.number,
        'Zahl',
      ),
      NodeOutputType.boolean => const NodeOutputTypeStyle._(
        OutputTypeColors.boolean,
        CupertinoIcons.check_mark_circled,
        'Wahrheitswert',
      ),
      NodeOutputType.json => const NodeOutputTypeStyle._(
        OutputTypeColors.json,
        CupertinoIcons.chevron_left_slash_chevron_right,
        'Strukturierte Daten',
      ),
      NodeOutputType.file => const NodeOutputTypeStyle._(
        OutputTypeColors.file,
        CupertinoIcons.doc,
        'Datei',
      ),
      NodeOutputType.media => const NodeOutputTypeStyle._(
        OutputTypeColors.media,
        CupertinoIcons.photo,
        'Medium',
      ),
      NodeOutputType.table => const NodeOutputTypeStyle._(
        OutputTypeColors.table,
        CupertinoIcons.table,
        'Tabelle',
      ),
    };
  }
}
