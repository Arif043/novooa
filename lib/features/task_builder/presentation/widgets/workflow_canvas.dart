import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';
import 'canvas_dots_painter.dart';
import 'animated_workflow_canvas_scene.dart';
import 'canvas_zoom_controls.dart';
import 'workflow_canvas_layout.dart';

class WorkflowCanvas extends StatefulWidget {
  const WorkflowCanvas({
    super.key,
    required this.graph,
    required this.selected,
    required this.onSelect,
    required this.onChoose,
    required this.onDrop,
    this.inspectorWidth = 0,
  });
  final WorkflowGraph graph;
  final NodeId? selected;
  final ValueChanged<WorkflowNode> onSelect;
  final ValueChanged<BausteinInsertion> onChoose;
  final void Function(BausteinChoice, BausteinInsertion) onDrop;
  final double inspectorWidth;
  @override
  State<WorkflowCanvas> createState() => _WorkflowCanvasState();
}

class _WorkflowCanvasState extends State<WorkflowCanvas>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation;
  Matrix4Tween? _zoomTween;
  Matrix4? _zoomTarget;
  WorkflowCanvasLayout? _layout;
  double? _layoutTextScale;
  Size _viewport = Size.zero;
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    _zoomAnimation =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 240),
        )..addListener(() {
          final tween = _zoomTween;
          if (tween == null) return;
          _transform.value = tween.transform(
            Curves.easeOutCubic.transform(_zoomAnimation.value),
          );
        });
  }

  @override
  void didUpdateWidget(WorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) _layout = null;
    final shift = (oldWidget.inspectorWidth - widget.inspectorWidth) / 2;
    if (shift != 0) {
      _stopZoom();
      _transform.value = _transform.value.clone()
        ..translateByDouble(
          shift / _transform.value.getMaxScaleOnAxis(),
          0,
          0,
          1,
        );
    }
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = _currentLayout();
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        if (!_positioned) {
          _positioned = true;
          _transform.value = Matrix4.translationValues(
            (constraints.maxWidth - layout.size.width) / 2,
            0,
            0,
          );
        }
        return Stack(
          children: [
            const Positioned.fill(child: CanvasDotsBackground()),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transform,
                onInteractionStart: (_) => _stopZoom(),
                constrained: false,
                minScale: .35,
                maxScale: 1.8,
                boundaryMargin: const EdgeInsets.all(1000),
                child: AnimatedWorkflowCanvasScene(
                  layout: layout,
                  selected: widget.selected,
                  onSelect: widget.onSelect,
                  onChoose: widget.onChoose,
                  onDrop: widget.onDrop,
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: CanvasZoomControls(
                transform: _transform,
                onZoom: _zoom,
                onFitAll: () => _fitAll(constraints, layout.size),
              ),
            ),
          ],
        );
      },
    );
  }

  void _zoom(double factor) {
    // Repeated clicks extend the pending destination without restarting from
    // an old frame; the viewport center remains the same scene point.
    final base = _zoomAnimation.isAnimating ? _zoomTarget! : _transform.value;
    final scale = base.getMaxScaleOnAxis();
    final nextScale = (scale * factor).clamp(.35, 1.8);
    final ratio = nextScale / scale;
    final center = Offset(
      math.max(1.0, _viewport.width - widget.inspectorWidth) / 2,
      _viewport.height / 2,
    );
    _animateTo(
      Matrix4.translationValues(
        center.dx - (center.dx - base.entry(0, 3)) * ratio,
        center.dy - (center.dy - base.entry(1, 3)) * ratio,
        0,
      )..scaleByDouble(nextScale, nextScale, nextScale, 1),
    );
  }

  void _animateTo(Matrix4 target) {
    _zoomAnimation.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      _zoomTarget = null;
      _transform.value = target;
      return;
    }
    _zoomTarget = target;
    _zoomTween = Matrix4Tween(begin: _transform.value.clone(), end: target);
    _zoomAnimation.forward(from: 0);
  }

  void _stopZoom() {
    _zoomAnimation.stop();
    _zoomTarget = null;
  }

  WorkflowCanvasLayout _currentLayout() {
    final textScale = MediaQuery.textScalerOf(context).scale(17) / 17;
    if (_layout == null || _layoutTextScale != textScale) {
      _layoutTextScale = textScale;
      _layout = WorkflowCanvasLayout(widget.graph, textScale: textScale);
    }
    return _layout!;
  }

  void _fitAll(BoxConstraints constraints, Size content) {
    final availableWidth = math.max(
      1.0,
      constraints.maxWidth - widget.inspectorWidth,
    );
    final scale = math
        .min(
          availableWidth / content.width,
          constraints.maxHeight / content.height,
        )
        .clamp(.35, 1.0);
    _animateTo(
      Matrix4.translationValues(
        (availableWidth - content.width * scale) / 2,
        0,
        0,
      )..scaleByDouble(scale, scale, scale, 1),
    );
  }
}
