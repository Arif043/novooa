import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/workflow_primitive_labels.dart';
import 'baustein_palette.dart';
import 'node_output_type_style.dart';
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

class _WorkflowCanvasState extends State<WorkflowCanvas>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _zoomAnimation;
  Matrix4Tween? _zoomTween;
  Matrix4? _zoomTarget;
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
    if (oldWidget.inspectorWidth != widget.inspectorWidth) {
      _stopZoom();
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
    _zoomAnimation.dispose();
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
                onInteractionStart: (_) => _stopZoom(),
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
                          ),
                        ),
                      ),
                      for (final link in layout.links)
                        if (link.labels.isNotEmpty &&
                            (!link.isReturn ||
                                WorkflowCanvasOptions.showReturnEdges))
                          if (_labelAnchor(layout, link)
                              case final Offset anchor)
                            Positioned(
                              left: anchor.dx,
                              top: anchor.dy,
                              child: FractionalTranslation(
                                translation: const Offset(-0.5, -0.5),
                                child: _CanvasLabelStack(link: link),
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
                                : AgentCursorAnchor(
                                    target: TaskBuilderCursorTargets.node(
                                      entry.node!.id,
                                    ),
                                    onActivate: () =>
                                        widget.onSelect(entry.node!),
                                    child: CompactWorkflowNode(
                                      node: entry.node!,
                                      selected:
                                          widget.selected == entry.node!.id,
                                      targeted: candidates.isNotEmpty,
                                      peers: entry.peers,
                                      onTap: () => widget.onSelect(entry.node!),
                                      onAdd: () =>
                                          widget.onChoose(entry.insertion),
                                    ),
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
                      tooltip: LocaleKeys.task_builder_canvas_zoom_out.tr(),
                      onPressed: () => _zoom(.8),
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 56,
                      child: ValueListenableBuilder<Matrix4>(
                        valueListenable: _transform,
                        builder: (_, matrix, _) => Text(
                          '${(matrix.getMaxScaleOnAxis() * 100).round()} %',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.task_builder_canvas_zoom_in.tr(),
                      onPressed: () => _zoom(1.25),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: LocaleKeys.task_builder_canvas_fit_all.tr(),
                      icon: const Icon(Icons.fit_screen),
                      onPressed: () {
                        final availableWidth = math.max(
                          1.0,
                          constraints.maxWidth - widget.inspectorWidth,
                        );
                        final scale = math
                            .min(
                              availableWidth / layout.size.width,
                              constraints.maxHeight / layout.size.height,
                            )
                            .clamp(.35, 1.0);
                        _animateTo(
                          Matrix4.translationValues(
                            (availableWidth - layout.size.width * scale) / 2,
                            0,
                            0,
                          )..scaleByDouble(scale, scale, scale, 1),
                        );
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
              label: Text(LocaleKeys.task_builder_canvas_connect_here.tr()),
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
                  key: ValueKey('compact-node-drag-${node.id.value}'),
                  data: node.id,
                  feedback: Material(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(node.config.primitive.label),
                    ),
                  ),
                  child: Tooltip(
                    message: LocaleKeys.task_builder_canvas_swap_block.tr(),
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
                // Deaktiviert: Dieser Button hängte bedingungslos einen
                // weiteren Nachfolger an jeden Baustein an, auch an
                // nicht-verzweigende Primitives — der Runner führt einen so
                // entstandenen zweiten Zweig einfach sequenziell mit aus,
                // ohne Zusammenführung (kein Guard in WorkflowGraph.addNode).
                // Das Anhängen des ersten Nachfolgers bleibt über den
                // separaten "+ Baustein hier verbinden"-Platzhalter möglich.
                // if (onAdd != null)
                // IconButton(
                //   tooltip: LocaleKeys.ui_baustein_verbinden.tr(),
                //   onPressed: onAdd,
                //   icon: const Icon(Icons.add, size: 20),
                // ),
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
  const WorkflowEdgesPainter(this.layout, this.colors);
  final WorkflowCanvasLayout layout;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in layout.links) {
      if (edge.isReturn && !WorkflowCanvasOptions.showReturnEdges) continue;
      final from = layout.rectangles[edge.from];
      final to = layout.rectangles[edge.to];
      if (from == null || to == null) continue;
      final start = from.bottomCenter;
      final end = to.topCenter;
      final color = edge.labels.isEmpty
          ? colors.onSurfaceVariant.withValues(alpha: .6)
          : colors.secondary;
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
    }
  }

  @override
  bool shouldRepaint(WorkflowEdgesPainter oldDelegate) => true;
}

/// Anker-Punkt für die Label-Chips eines Pfeils — exakt derselbe
/// Mittelpunkt, den der Pfeil selbst in [WorkflowEdgesPainter] anpeilt
/// (`start`/`end`/`middle`), damit Pfeil und Chip-Stapel optisch
/// zusammenpassen.
Offset? _labelAnchor(WorkflowCanvasLayout layout, CanvasLink link) {
  final from = layout.rectangles[link.from];
  final to = layout.rectangles[link.to];
  if (from == null || to == null) return null;
  final start = from.bottomCenter;
  final end = to.topCenter;
  return Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
}

/// Die Chips eines Pfeils als zentrierte, vertikale Reihe — üblicherweise
/// genau einer (Bedingungs-Label oder Ausgabename), bei mehreren
/// fachlichen Ausgabewerten (z.B. strukturierte Prompt-Ausgabe) aber
/// mehrere untereinander.
class _CanvasLabelStack extends StatelessWidget {
  const _CanvasLabelStack({required this.link});

  final CanvasLink link;

  @override
  Widget build(BuildContext context) {
    final background = link.isCondition
        ? Colors.grey[600] ?? Colors.grey
        : Theme.of(context).colorScheme.primaryContainer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < link.labels.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _CanvasLabelChip(label: link.labels[i], background: background),
        ],
      ],
    );
  }
}

/// Ein einzelner Label-Chip. Ohne [CanvasLabel.editTarget] (strukturelle
/// Labels wie "Für jedes Element") reiner Text ohne Geste. Mit Edit-Ziel:
/// Doppelklick macht den Text direkt inline editierbar (voll selektiert,
/// bereit zum Überschreiben) — bewusst kein Dialog, die Änderung wird bei
/// Enter/Fokusverlust sofort fachlich übernommen (siehe [_submit]).
class _CanvasLabelChip extends StatefulWidget {
  const _CanvasLabelChip({required this.label, required this.background});

  final CanvasLabel label;
  final Color background;

  @override
  State<_CanvasLabelChip> createState() => _CanvasLabelChipState();
}

class _CanvasLabelChipState extends State<_CanvasLabelChip> {
  TextEditingController? _controller;
  FocusNode? _focusNode;

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  void _startEditing() {
    if (widget.label.editTarget == null) return;
    final controller = TextEditingController(text: widget.label.text);
    final focusNode = FocusNode();
    setState(() {
      _controller = controller;
      _focusNode = focusNode;
    });
    // Erst nach dem Aufbau des Textfelds fokussieren/selektieren — sonst
    // existiert der EditableText-State noch nicht.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    });
  }

  void _submit(BuildContext context) {
    final controller = _controller;
    final target = widget.label.editTarget;
    if (controller == null) return;
    final value = controller.text.trim();
    setState(() {
      _controller = null;
      _focusNode = null;
    });
    controller.dispose();
    if (target == null || value.isEmpty || value == widget.label.text) return;
    _applyEdit(context, target, value);
  }

  void _applyEdit(
    BuildContext context,
    CanvasLabelEditTarget target,
    String value,
  ) {
    final cubit = context.read<TaskBuilderCubit>();
    switch (target) {
      case OutputNameEditTarget(:final nodeId):
        cubit.updateNodeOutputName(nodeId, value);
      case ConditionalBranchEditTarget(
        :final conditionalNodeId,
        :final branchId,
      ):
        cubit.updateConditionalBranchLabel(
          conditionalNodeId: conditionalNodeId,
          branchId: branchId,
          label: value,
        );
      case StructuredFieldEditTarget(:final nodeId, :final fieldIndex):
        cubit.renamePromptStructuredFieldName(
          nodeId: nodeId,
          fieldIndex: fieldIndex,
          name: value,
        );
      case DialogFieldEditTarget(:final nodeId, :final fieldIndex):
        cubit.renameDialogInputFieldName(
          nodeId: nodeId,
          fieldIndex: fieldIndex,
          name: value,
        );
      case ChannelEventFieldEditTarget(:final nodeId, :final field):
        cubit.renameChannelEventOutputName(
          nodeId: nodeId,
          field: field,
          name: value,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final editable = widget.label.editTarget != null;
    final editing = _controller != null;
    final labelType = widget.label.type;
    final typeStyle = labelType == null
        ? null
        : NodeOutputTypeStyle.of(labelType);
    final chip = Container(
      constraints: const BoxConstraints(minWidth: 32),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: typeStyle?.color ?? widget.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: _withTypeIcon(
        typeStyle,
        editing
            ? IntrinsicWidth(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  style: textStyle,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    focusedBorder: UnderlineInputBorder(
                      borderSide: .new(color: SyscatTheme.primaryOrange),
                    ),
                  ),
                  onSubmitted: (_) => _submit(context),
                  onTapOutside: (_) => _submit(context),
                ),
              )
            : Text(widget.label.text, style: textStyle),
      ),
    );
    if (!editable) return _typeSemantics(typeStyle, chip);
    return Semantics(
      button: true,
      label:
          'Label "${widget.label.text}"${_typeSuffix(typeStyle)} bearbeiten, Doppelklick',
      child: GestureDetector(onDoubleTap: _startEditing, child: chip),
    );
  }

  Widget _withTypeIcon(NodeOutputTypeStyle? style, Widget content) {
    if (style == null) return content;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(style.icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(child: content),
      ],
    );
  }

  Widget _typeSemantics(NodeOutputTypeStyle? style, Widget chip) {
    if (style == null) return chip;
    return Semantics(
      label: '${widget.label.text}${_typeSuffix(style)}',
      child: chip,
    );
  }

  String _typeSuffix(NodeOutputTypeStyle? style) =>
      style == null ? '' : ' (${style.label})';
}
