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
    required this.onNodeDragStart,
    required this.onNodeDrag,
    required this.onNodeDragEnd,
  });

  final List<KnowledgeNote> notes;
  final String? selectedNoteId;
  final KnowledgeGraphSimulation simulation;
  final ValueChanged<String> onNodeDragStart;
  final void Function(String noteId, Offset position, Offset delta) onNodeDrag;
  final VoidCallback onNodeDragEnd;

  Map<String, Offset> get positions => simulation.positions;

  @override
  Widget build(BuildContext context) {
    final selected = selectedNoteId;
    final neighbours = selected == null
        ? const <String>{}
        : simulation.neighboursOf(selected);
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
              ),
            ),
          ),
          for (final note in notes)
            KnowledgeGraphNode(
              key: ValueKey('knowledge-graph-node-${note.id}'),
              note: note,
              emphasis: _emphasisOf(note.id, neighbours),
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

  KnowledgeGraphEmphasis _emphasisOf(String id, Set<String> neighbours) {
    if (selectedNoteId == null) return KnowledgeGraphEmphasis.normal;
    if (id == selectedNoteId) return KnowledgeGraphEmphasis.selected;
    return neighbours.contains(id)
        ? KnowledgeGraphEmphasis.neighbour
        : KnowledgeGraphEmphasis.dimmed;
  }
}
