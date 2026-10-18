import 'package:flutter/material.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_graph_node.dart';
import 'knowledge_graph_painter.dart';
import 'knowledge_graph_simulation.dart';

class KnowledgeGraphCanvas extends StatelessWidget {
  const KnowledgeGraphCanvas({
    super.key,
    required this.notes,
    required this.selectedNoteId,
    required this.simulation,
    this.reach = const {},
    required this.onNodeDragStart,
    required this.onNodeDrag,
    required this.onNodeDragEnd,
  });

  final List<KnowledgeNote> notes;
  final String? selectedNoteId;
  final KnowledgeGraphSimulation simulation;

  /// Was ein Prompt mit der gewählten Notiz sieht: Notiz-ID → Ebene
  /// (`KnowledgeNoteReach`).
  final Map<String, int> reach;
  final ValueChanged<String> onNodeDragStart;
  final void Function(String noteId, Offset position, Offset delta) onNodeDrag;
  final VoidCallback onNodeDragEnd;

  Map<String, Offset> get positions => simulation.positions;

  @override
  Widget build(BuildContext context) {
    final selected = selectedNoteId;
    return SizedBox.fromSize(
      size: simulation.canvasSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: KnowledgeGraphPainter(
                links: simulation.links,
                positions: positions,
                colorScheme: Theme.of(context).colorScheme,
                selectedNoteId: selected,
                highlightedLinks: _reachedLinks(),
              ),
            ),
          ),
          for (final note in notes)
            KnowledgeGraphNode(
              key: ValueKey('knowledge-graph-node-${note.id}'),
              note: note,
              emphasis: _emphasisOf(note.id),
              degree: simulation.degrees[note.id] ?? 0,
              position: positions[note.id] ?? Offset.zero,
              onDragStart: () => onNodeDragStart(note.id),
              onDragUpdate: (delta) {
                onNodeDrag(note.id, positions[note.id] ?? Offset.zero, delta);
              },
              onDragEnd: onNodeDragEnd,
            ),
        ],
      ),
    );
  }

  KnowledgeGraphEmphasis _emphasisOf(String id) {
    if (selectedNoteId == null) return KnowledgeGraphEmphasis.normal;
    return switch (reach[id]) {
      0 => KnowledgeGraphEmphasis.selected,
      1 => KnowledgeGraphEmphasis.directlyLinked,
      null => KnowledgeGraphEmphasis.dimmed,
      _ => KnowledgeGraphEmphasis.indirectlyLinked,
    };
  }

  /// Ausgehende Links zwischen Notizen im Kontext.
  Set<(String, String)> _reachedLinks() => {
    for (final note in notes)
      if (reach.containsKey(note.id))
        for (final target in note.outgoingLinks)
          if (target != note.id && reach.containsKey(target)) (note.id, target),
  };
}
