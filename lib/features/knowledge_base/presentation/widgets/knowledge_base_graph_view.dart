import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/knowledge_note.dart';
import 'knowledge_graph_canvas.dart';
import 'knowledge_graph_painter.dart';
import 'knowledge_graph_physics.dart';
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

class _KnowledgeBaseGraphViewState extends State<KnowledgeBaseGraphView>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  final Map<String, Offset> _positions = {};
  final Map<String, Offset> _velocities = {};
  final Map<String, Offset> _restPositions = {};
  Duration _previousTick = Duration.zero;
  double _pendingSeconds = 0;
  late final AnimationController _physicsController;
  String? _draggingNoteId;
  String? _settlingNoteId;
  Size _lastCanvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _physicsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tickPhysics);
  }

  @override
  void didUpdateWidget(KnowledgeBaseGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final noteIds = widget.notes.map((note) => note.id).toSet();
    _positions.removeWhere((noteId, _) => !noteIds.contains(noteId));
    _velocities.removeWhere((noteId, _) => !noteIds.contains(noteId));
    _restPositions.removeWhere((noteId, _) => !noteIds.contains(noteId));
  }

  @override
  void dispose() {
    _physicsController.dispose();
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
        if (widget.notes.any((note) => !_positions.containsKey(note.id))) {
          final layout = KnowledgeGraphLayout(widget.notes, canvasSize);
          _syncPositions(layout.positions);
        }
        _lastCanvasSize = canvasSize;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                    canvasSize: canvasSize,
                    positions: _positions,
                    onNodeDragStart: _startNodeDrag,
                    onNodeDrag: (noteId, position, delta) {
                      _moveNode(noteId, position, delta, canvasSize);
                    },
                    onNodeDragEnd: _endNodeDrag,
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
    _physicsController.stop();
    setState(() {
      _positions.clear();
      _velocities.clear();
      _restPositions.clear();
      _draggingNoteId = null;
      _settlingNoteId = null;
    });
  }

  void _startNodeDrag(String noteId) {
    _physicsController.stop();
    _velocities.clear();
    setState(() {
      _draggingNoteId = noteId;
      _settlingNoteId = null;
      _velocities[noteId] = Offset.zero;
    });
    _startPhysics();
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
      _positions[noteId] = _clamp(currentPosition + canvasDelta, canvasSize);
      _velocities[noteId] = Offset.zero;
    });
  }

  void _endNodeDrag() {
    final noteId = _draggingNoteId;
    setState(() {
      _draggingNoteId = null;
      _settlingNoteId = noteId;
    });
    if (noteId != null) {
      // A deliberate drop becomes the new resting position, without a fling.
      _restPositions[noteId] = _positions[noteId]!;
      _velocities[noteId] = Offset.zero;
    }
    _startPhysics();
  }

  void _syncPositions(Map<String, Offset> layoutPositions) {
    for (final entry in layoutPositions.entries) {
      _positions.putIfAbsent(entry.key, () => entry.value);
      _restPositions.putIfAbsent(entry.key, () => entry.value);
    }
  }

  void _startPhysics() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (!_physicsController.isAnimating) {
      _previousTick = Duration.zero;
      _pendingSeconds = 0;
      _physicsController.repeat(period: const Duration(milliseconds: 16));
    }
  }

  void _tickPhysics() {
    if (_lastCanvasSize == Size.zero || widget.notes.isEmpty) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _physicsController.stop();
      _velocities.clear();
      return;
    }
    final elapsed = _physicsController.lastElapsedDuration ?? Duration.zero;
    final seconds = (elapsed - _previousTick).inMicroseconds / 1000000;
    _previousTick = elapsed;
    _pendingSeconds += seconds.clamp(0, 1 / 15);
    const stepSeconds = 1 / 60;
    if (_pendingSeconds < stepSeconds) return;
    final physics = KnowledgeGraphPhysics(
      notes: widget.notes,
      canvasSize: _lastCanvasSize,
      pinnedNoteId: _draggingNoteId ?? _settlingNoteId,
      restPositions: _restPositions,
    );
    var moving = false;
    while (_pendingSeconds >= stepSeconds) {
      moving = physics.step(_positions, _velocities);
      _pendingSeconds -= stepSeconds;
    }
    if (!moving && _draggingNoteId == null) _physicsController.stop();
    setState(() {});
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
