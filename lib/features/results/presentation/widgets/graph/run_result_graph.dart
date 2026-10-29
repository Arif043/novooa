import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../task_builder/domain/entities/workflow_graph.dart';
import '../../../../task_builder/presentation/widgets/canvas_dots_painter.dart';
import '../../../../task_builder/presentation/widgets/canvas_zoom_controls.dart';
import '../../../../task_builder/presentation/widgets/workflow_canvas_frame.dart';
import '../../cubits/run_result_state.dart';
import 'result_canvas.dart';
import 'run_result_scene.dart';

/// Der Ergebnisgraph mit Verschieben und Zoomen; passt sich beim Öffnen ein.
class RunResultGraph extends StatefulWidget {
  const RunResultGraph({
    super.key,
    required this.graph,
    required this.state,
    required this.onSelectNode,
    required this.onSelectRound,
  });

  final WorkflowGraph graph;
  final RunResultReady state;
  final ValueChanged<String> onSelectNode;
  final void Function(String loopNodeId, int round) onSelectRound;

  @override
  State<RunResultGraph> createState() => _RunResultGraphState();
}

class _RunResultGraphState extends State<RunResultGraph> {
  static const _minimumScale = 0.35;
  static const _maximumScale = 1.8;

  /// Darunter sind Karten nicht mehr lesbar.
  static const _readableScale = 0.7;

  final _transform = TransformationController();
  CanvasFrame? _frame;
  double? _textScale;
  Size _viewport = Size.zero;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _currentFrame(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _fitOnFirstLayout(constraints.biggest, frame.size);
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: CanvasDotsPainter(
                  Theme.of(context).colorScheme.outlineVariant,
                  Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
              ),
            ),
            InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: _minimumScale,
              maxScale: _maximumScale,
              boundaryMargin: const EdgeInsets.all(AppSpacing.section * 4),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: RunResultScene(
                  frame: frame,
                  state: widget.state,
                  onSelectNode: widget.onSelectNode,
                  onSelectRound: widget.onSelectRound,
                ),
              ),
            ),
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: CanvasZoomControls(
                transform: _transform,
                onZoom: _zoom,
                onFitAll: () => _fit(constraints.biggest, frame.size),
              ),
            ),
          ],
        );
      },
    );
  }

  CanvasFrame _currentFrame(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(17) / 17;
    if (_frame == null || _textScale != textScale) {
      _textScale = textScale;
      _frame = resultCanvasFrame(widget.graph, textScale: textScale);
    }
    return _frame!;
  }

  void _fitOnFirstLayout(Size viewport, Size content) {
    if (_viewport == viewport) return;
    _viewport = viewport;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit(viewport, content);
    });
  }

  /// An die Breite angepasst, oben beginnend: Ein langer Ablauf bleibt
  /// lesbar und wird gescrollt, statt auf Briefmarkengröße zu schrumpfen.
  void _fit(Size viewport, Size content) {
    final paddedWidth = content.width + AppSpacing.xxl;
    final scale = (viewport.width / paddedWidth).clamp(_readableScale, 1.0);
    final left = math.max(0.0, (viewport.width - paddedWidth * scale) / 2);
    _transform.value = Matrix4.translationValues(left, 0, 0)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void _zoom(double factor) {
    final current = _transform.value;
    final scale = current.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(_minimumScale, _maximumScale);
    final ratio = next / scale;
    final center = Offset(_viewport.width / 2, _viewport.height / 2);
    _transform.value = Matrix4.translationValues(
      center.dx - (center.dx - current.entry(0, 3)) * ratio,
      center.dy - (center.dy - current.entry(1, 3)) * ratio,
      0,
    )..scaleByDouble(next, next, next, 1);
  }
}
