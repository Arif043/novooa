import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import '../../domain/services/knowledge_note_reach.dart';
import 'knowledge_graph_background.dart';
import 'knowledge_graph_canvas.dart';
import 'knowledge_graph_simulation.dart';
import 'knowledge_graph_simulation_ticker.dart';
import 'knowledge_graph_toolbar.dart';

/// Der Wissensgraph als Live-Kraftsimulation ([KnowledgeGraphSimulation]):
/// Er entfaltet sich beim Öffnen, reagiert beim Ziehen als Ganzes und
/// schwingt danach aus.
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

class _KnowledgeBaseGraphViewState extends State<KnowledgeBaseGraphView>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  final _simulation = KnowledgeGraphSimulation(
    canvasSize: const Size(1200, 760),
  );
  late final _ticker = KnowledgeGraphSimulationTicker(
    vsync: this,
    simulation: _simulation,
    onFrame: () => setState(() {}),
  );
  String? _draggingNoteId;
  bool _notesPending = true;

  @override
  void didUpdateWidget(KnowledgeBaseGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) _notesPending = true;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) {
      return const Center(child: Text('Keine Notizen.'));
    }
    final selected = widget.selectedNoteId;
    final reach = selected == null
        ? const <String, int>{}
        : const KnowledgeNoteReach()(selected, widget.notes);
    return LayoutBuilder(
      builder: (context, constraints) {
        _simulation.canvasSize = _canvasSizeFor(constraints.biggest);
        if (_notesPending) {
          _notesPending = false;
          _simulation.setNotes(widget.notes);
          _run();
        }
        // Eckig: Die Leinwand füllt den Dokumentbereich bis an Trennlinie und Kartenrand;
        // unten rundet die umgebende Karte ab.
        return ClipRect(
          child: KnowledgeGraphBackground(
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: _draggingNoteId == null,
                  scaleEnabled: _draggingNoteId == null,
                  minScale: 0.35,
                  maxScale: 3.4,
                  boundaryMargin: const EdgeInsets.all(AppSpacing.section),
                  child: KnowledgeGraphCanvas(
                    notes: widget.notes,
                    selectedNoteId: widget.selectedNoteId,
                    simulation: _simulation,
                    reach: reach,
                    onNodeDragStart: _startNodeDrag,
                    onNodeDrag: _moveNode,
                    onNodeDragEnd: _endNodeDrag,
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: KnowledgeGraphToolbar(
                    onResetView: _resetView,
                    contextNoteCount: reach.isEmpty ? null : reach.length,
                  ),
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
    setState(() {
      _draggingNoteId = null;
      _simulation
        ..endDrag()
        ..restart();
    });
    _run();
  }

  void _startNodeDrag(String noteId) {
    setState(() {
      _draggingNoteId = noteId;
      _simulation.startDrag(noteId);
    });
    _run();
  }

  void _moveNode(String noteId, Offset currentPosition, Offset screenDelta) {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    setState(
      () => _simulation.dragTo(noteId, currentPosition + screenDelta / scale),
    );
    _run();
  }

  void _endNodeDrag() {
    setState(() {
      _draggingNoteId = null;
      _simulation.endDrag();
    });
    _run();
  }

  /// Bei reduzierter Bewegung rechnet die Simulation sofort bis zur Ruhe.
  void _run() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticker.stop();
      _simulation.settle();
      return;
    }
    _ticker.ensureRunning();
  }

  Size _canvasSizeFor(Size viewport) {
    return Size(
      viewport.width < 1200 ? 1200 : viewport.width,
      viewport.height < 760 ? 760 : viewport.height,
    );
  }
}
