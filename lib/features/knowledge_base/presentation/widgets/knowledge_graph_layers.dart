import 'dart:math' as math;
import 'dart:ui';

import '../../domain/entities/knowledge_note.dart';
import '../../domain/services/knowledge_note_reach.dart';

/// Startanordnung des Wissensgraphen nach Höhe: Je mehr Notizen eine Notiz
/// über ihre ausgehenden Links direkt und indirekt erreicht, desto weiter oben
/// steht sie. Notizen mit gleicher Zahl bilden eine Ebene; passt eine Ebene
/// nicht in die Breite, bricht sie in weitere Reihen um.
class KnowledgeGraphLayers {
  const KnowledgeGraphLayers({required this.spacing, required this.margin});

  /// Abstand zwischen Nachbarn einer Reihe und zwischen Reihen.
  final double spacing;

  /// Freier Rand der Leinwand.
  final double margin;

  Map<String, Offset> positionsOf(List<KnowledgeNote> notes, Size canvas) {
    final rows = _rowsOf(notes, _perRow(canvas.width));
    final rowSpacing = _fitted(spacing, canvas.height, rows.length);
    final top = canvas.height / 2 - (rows.length - 1) * rowSpacing / 2;
    return {
      for (final (rowIndex, row) in rows.indexed)
        for (final (index, id) in row.indexed)
          id: Offset(
            canvas.width / 2 + (index - (row.length - 1) / 2) * spacing,
            top + rowIndex * rowSpacing,
          ),
    };
  }

  /// Notiz-ID → Zahl der direkt und indirekt verlinkten Notizen.
  static Map<String, int> reachCountsOf(List<KnowledgeNote> notes) {
    final reach = KnowledgeNoteReach(
      maxDepth: notes.length,
      maxNotes: notes.length,
    );
    return {
      for (final note in notes) note.id: reach(note.id, notes).length - 1,
    };
  }

  List<List<String>> _rowsOf(List<KnowledgeNote> notes, int perRow) {
    final counts = reachCountsOf(notes);
    final levels = counts.values.toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return [
      for (final level in levels)
        ..._chunked([
          for (final note in notes)
            if (counts[note.id] == level) note.id,
        ], perRow),
    ];
  }

  int _perRow(double width) =>
      math.max(1, ((width - 2 * margin) / spacing).floor() + 1);

  /// Verkleinert den Reihenabstand, wenn alle Reihen sonst nicht passen.
  double _fitted(double preferred, double extent, int count) {
    if (count < 2) return preferred;
    return math.min(preferred, (extent - 2 * margin) / (count - 1));
  }

  static List<List<String>> _chunked(List<String> ids, int size) => [
    for (var start = 0; start < ids.length; start += size)
      ids.sublist(start, math.min(start + size, ids.length)),
  ];
}
