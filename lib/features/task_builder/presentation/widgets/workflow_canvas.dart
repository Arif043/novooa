import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/workflow_primitive_labels.dart';
import 'baustein_palette.dart';
import 'workflow_canvas_layout.dart';
import 'workflow_canvas_options.dart';

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

class _WorkflowCanvasState extends State<WorkflowCanvas> {
  final _transform = TransformationController();
  bool _positioned = false;
  @override
  void didUpdateWidget(WorkflowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inspectorWidth != widget.inspectorWidth) {
      final matrix = _transform.value.clone();
      matrix.setEntry(
        0,
        3,
        matrix.entry(0, 3) +
            (oldWidget.inspectorWidth - widget.inspectorWidth) / 2,
      );
      _transform.value = matrix;
    }
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = WorkflowCanvasLayout(
      widget.graph,
      textScale: MediaQuery.textScalerOf(context).scale(17) / 17,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
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
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: CanvasDotsPainter(
                    Theme.of(context).colorScheme.outlineVariant,
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transform,
                constrained: false,
                minScale: .35,
                maxScale: 1.8,
                boundaryMargin: const EdgeInsets.all(1000),
                child: SizedBox(
                  width: layout.size.width,
                  height: layout.size.height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WorkflowEdgesPainter(
                            layout,
                            Theme.of(context).colorScheme,
                            Theme.of(context).textTheme.labelMedium!,
                          ),
                        ),
                      ),
                      for (final entry in layout.entries.values)
                        Positioned.fromRect(
                          rect: layout.rectangles[entry.id]!,
                          child: DragTarget<BausteinChoice>(
                            onWillAcceptWithDetails: (_) => entry.canInsert,
                            onAcceptWithDetails: (details) =>
                                widget.onDrop(details.data, entry.insertion),
                            builder: (context, candidates, _) =>
                                entry.node == null
                                ? _PathInsertion(
                                    entry: entry,
                                    targeted: candidates.isNotEmpty,
                                    onPressed: () =>
                                        widget.onChoose(entry.insertion),
                                  )
                                : CompactWorkflowNode(
                                    node: entry.node!,
                                    selected: widget.selected == entry.node!.id,
                                    targeted: candidates.isNotEmpty,
                                    peers: entry.peers,
                                    onTap: () => widget.onSelect(entry.node!),
                                    onAdd: () =>
                                        widget.onChoose(entry.insertion),
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Verkleinern',
                      onPressed: () => _zoom(.8),
                      icon: const Icon(Icons.remove),
                    ),
                    ValueListenableBuilder<Matrix4>(
                      valueListenable: _transform,
                      builder: (_, matrix, _) => Text(
                        '${(matrix.getMaxScaleOnAxis() * 100).round()} %',
                      ),
                    ),
                    IconButton(
                      tooltip: 'Vergrößern',
                      onPressed: () => _zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Gesamten Arbeitsplan anzeigen',
                      icon: const Icon(Icons.fit_screen),
                      onPressed: () {
                        final scale = math
                            .min(
                              constraints.maxWidth / layout.size.width,
                              constraints.maxHeight / layout.size.height,
                            )
                            .clamp(.35, 1.0);
                        _transform.value = Matrix4.translationValues(
                          (constraints.maxWidth - layout.size.width * scale) /
                              2,
                          0,
                          0,
                        )..scaleByDouble(scale, scale, scale, 1);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _zoom(double factor) {
    final scale = _transform.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(.35, 1.8) / scale;
    _transform.value = _transform.value.clone()
      ..scaleByDouble(next, next, next, 1);
  }
}

class _PathInsertion extends StatelessWidget {
  const _PathInsertion({
    required this.entry,
    required this.targeted,
    required this.onPressed,
  });
  final CanvasEntry entry;
  final bool targeted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.continuationLabel case final String label) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          if (entry.canInsert) const SizedBox(height: 12),
        ],
        if (entry.canInsert)
          Expanded(
            child: OutlinedButton.icon(
              key: ValueKey('path-insertion-${entry.id}'),
              style: OutlinedButton.styleFrom(
                backgroundColor: targeted
                    ? colors.primaryContainer.withValues(alpha: .12)
                    : colors.surface.withValues(alpha: .8),
                side: BorderSide(
                  color: targeted ? colors.primary : colors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: const Text('Baustein hier verbinden'),
            ),
          ),
      ],
    );
  }
}

class CompactWorkflowNode extends StatelessWidget {
  const CompactWorkflowNode({
    super.key,
    required this.node,
    required this.selected,
    required this.onTap,
    this.onAdd,
    this.targeted = false,
    this.peers = const {},
  });
  final WorkflowNode node;
  final bool selected;
  final bool targeted;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final Set<NodeId> peers;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DragTarget<NodeId>(
      onWillAcceptWithDetails: (details) =>
          details.data != node.id && peers.contains(details.data),
      onAcceptWithDetails: (details) =>
          context.read<TaskBuilderCubit>().swapNodes(details.data, node.id),
      builder: (context, candidates, _) => Material(
        elevation: selected ? 4 : 1,
        shadowColor: colors.shadow.withValues(alpha: .12),
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected || targeted || candidates.isNotEmpty
                ? colors.primaryContainer
                : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('compact-node-${node.id.value}'),
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Draggable<NodeId>(
                  data: node.id,
                  feedback: Material(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(node.config.primitive.label),
                    ),
                  ),
                  child: Tooltip(
                    message: 'Baustein tauschen',
                    child: CircleAvatar(
                      radius: 23,
                      backgroundColor: colors.primaryContainer.withValues(
                        alpha: .12,
                      ),
                      child: Icon(
                        bausteinIcon(node.config.primitive),
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.config.primitive.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Tooltip(
                        message: node.id.value,
                        child: Text(
                          'ID: ${node.id.value}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onAdd != null)
                  IconButton(
                    tooltip: 'Baustein verbinden',
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 20),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CanvasDotsPainter extends CustomPainter {
  const CanvasDotsPainter(this.color, this.background);
  final Color color;
  final Color background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()..color = color.withValues(alpha: .4);
    for (double x = 12; x < size.width; x += 22) {
      for (double y = 12; y < size.height; y += 22) {
        canvas.drawCircle(Offset(x, y), .8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CanvasDotsPainter oldDelegate) =>
      color != oldDelegate.color || background != oldDelegate.background;
}

class WorkflowEdgesPainter extends CustomPainter {
  const WorkflowEdgesPainter(this.layout, this.colors, this.labelStyle);
  final WorkflowCanvasLayout layout;
  final ColorScheme colors;
  final TextStyle labelStyle;
  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in layout.links) {
      if (edge.isReturn && !WorkflowCanvasOptions.showReturnEdges) continue;
      final from = layout.rectangles[edge.from];
      final to = layout.rectangles[edge.to];
      if (from == null || to == null) continue;
      final start = from.bottomCenter;
      final end = to.topCenter;
      final color = edge.label == null
          ? colors.onSurfaceVariant.withValues(alpha: .6)
          : colors.primary;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(start.dx, start.dy);
      final middle = (start.dy + end.dy) / 2;
      if (edge.isReturn && end.dy > start.dy) {
        // Collect returns just above the continuation, below every branch.
        final joinY = end.dy - 32;
        path.lineTo(start.dx, joinY);
        path.lineTo(end.dx, joinY);
        path.lineTo(end.dx, end.dy);
      } else if (end.dy > start.dy && (start.dx - end.dx).abs() < .01) {
        path.lineTo(end.dx, end.dy);
      } else if (end.dy > start.dy && end.dy - start.dy < 200) {
        path.cubicTo(start.dx, middle, end.dx, middle, end.dx, end.dy);
      } else {
        // Route long and backward edges outside the cards.
        final side = math.min(from.left, to.left) - 30;
        path.lineTo(start.dx, start.dy + 20);
        path.lineTo(side, start.dy + 20);
        path.lineTo(side, end.dy - 24);
        path.lineTo(end.dx, end.dy - 24);
        path.lineTo(end.dx, end.dy);
      }
      if (edge.isReturn) {
        for (final metric in path.computeMetrics()) {
          for (double offset = 0; offset < metric.length; offset += 12) {
            canvas.drawPath(
              metric.extractPath(offset, math.min(offset + 6, metric.length)),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
      canvas.drawPath(
        Path()
          ..moveTo(end.dx - 5, end.dy - 7)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx + 5, end.dy - 7),
        paint,
      );
      if (edge.label case final String label when label.isNotEmpty) {
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: labelStyle.copyWith(
              color: colors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 240);
        final center = Offset((start.dx + end.dx) / 2, middle);
        final rect = Rect.fromCenter(
          center: center,
          width: text.width + 24,
          height: text.height + 12,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(20)),
          Paint()..color = colors.surfaceContainerHighest,
        );
        text.paint(canvas, Offset(rect.left + 12, rect.top + 6));
      }
    }
  }

  @override
  bool shouldRepaint(WorkflowEdgesPainter oldDelegate) => true;
}
