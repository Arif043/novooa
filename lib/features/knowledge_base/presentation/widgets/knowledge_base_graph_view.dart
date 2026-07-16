import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_graph_node.dart';
import 'knowledge_graph_painter.dart';
import 'knowledge_graph_toolbar.dart';

class KnowledgeBaseGraphView extends StatefulWidget {
  const KnowledgeBaseGraphView({
    super.key,
    required this.notes,
    required this.selectedNoteId,
  });

  final List<KnowledgeNote> notes;
  final String? selectedNoteId;

  @override
  State<KnowledgeBaseGraphView> createState() => _KnowledgeBaseGraphViewState();
}

class _KnowledgeBaseGraphViewState extends State<KnowledgeBaseGraphView> {
  final _transformationController = TransformationController();
  final Map<String, Offset> _manualPositions = {};

  @override
  void didUpdateWidget(KnowledgeBaseGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final noteIds = widget.notes.map((note) => note.id).toSet();
    _manualPositions.removeWhere((noteId, _) => !noteIds.contains(noteId));
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return const Center(child: Text('Keine Notizen.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = _canvasSizeFor(constraints.biggest);
        final layout = KnowledgeGraphLayout(widget.notes, canvasSize);
        final positions = _positionsFor(layout.positions);
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.inverseSurface,
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.35,
                  maxScale: 3.4,
                  boundaryMargin: const EdgeInsets.all(AppSpacing.section),
                  child: _GraphCanvas(
                    notes: widget.notes,
                    selectedNoteId: widget.selectedNoteId,
                    canvasSize: canvasSize,
                    positions: positions,
                    onNodeDrag: (noteId, position, delta) {
                      _moveNode(noteId, position, delta, canvasSize);
                    },
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: KnowledgeGraphToolbar(onResetView: _resetView),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(_manualPositions.clear);
  }

  Map<String, Offset> _positionsFor(Map<String, Offset> layoutPositions) {
    return {
      for (final entry in layoutPositions.entries)
        entry.key: _manualPositions[entry.key] ?? entry.value,
    };
  }

  void _moveNode(
    String noteId,
    Offset currentPosition,
    Offset screenDelta,
    Size canvasSize,
  ) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final canvasDelta = screenDelta / scale;
    setState(() {
      _manualPositions[noteId] = _clamp(
        currentPosition + canvasDelta,
        canvasSize,
      );
    });
  }

  Offset _clamp(Offset value, Size canvasSize) {
    return Offset(
      value.dx.clamp(AppSpacing.section, canvasSize.width - AppSpacing.section),
      value.dy.clamp(
        AppSpacing.section,
        canvasSize.height - AppSpacing.section,
      ),
    );
  }

  Size _canvasSizeFor(Size viewport) {
    return Size(
      viewport.width < 1200 ? 1200 : viewport.width,
      viewport.height < 760 ? 760 : viewport.height,
    );
  }
}

class _GraphCanvas extends StatelessWidget {
  const _GraphCanvas({
    required this.notes,
    required this.selectedNoteId,
    required this.canvasSize,
    required this.positions,
    required this.onNodeDrag,
  });

  final List<KnowledgeNote> notes;
  final String? selectedNoteId;
  final Size canvasSize;
  final Map<String, Offset> positions;
  final void Function(String noteId, Offset position, Offset delta) onNodeDrag;

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
              onDragUpdate: (delta) {
                onNodeDrag(note.id, positions[note.id] ?? Offset.zero, delta);
              },
            ),
        ],
      ),
    );
  }
}
