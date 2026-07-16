import 'package:flutter/material.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_graph_node.dart';
import 'knowledge_graph_painter.dart';

class KnowledgeGraphCanvas extends StatelessWidget {
  const KnowledgeGraphCanvas({
    super.key,
    required this.notes,
    required this.selectedNoteId,
    required this.canvasSize,
    required this.positions,
    required this.onNodeDragStart,
    required this.onNodeDrag,
    required this.onNodeDragEnd,
  });

  final List<KnowledgeNote> notes;
  final String? selectedNoteId;
  final Size canvasSize;
  final Map<String, Offset> positions;
  final ValueChanged<String> onNodeDragStart;
  final void Function(String noteId, Offset position, Offset delta) onNodeDrag;
  final VoidCallback onNodeDragEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: canvasSize.width,
      height: canvasSize.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: KnowledgeGraphPainter(
                notes: notes,
                positions: positions,
                colorScheme: Theme.of(context).colorScheme,
                selectedNoteId: selectedNoteId,
              ),
            ),
          ),
          for (final note in notes)
            KnowledgeGraphNode(
              note: note,
              selected: note.id == selectedNoteId,
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
}
