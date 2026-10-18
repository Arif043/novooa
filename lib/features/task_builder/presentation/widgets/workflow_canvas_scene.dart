import 'package:flutter/material.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_anchor.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_cursor_targets.dart';

import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';
import 'canvas_label_stack.dart';
import 'canvas_path_insertion.dart';
import 'compact_workflow_node.dart';
import 'workflow_canvas_frame.dart';
import 'workflow_canvas_layout.dart';
import 'workflow_canvas_options.dart';
import 'workflow_edges_painter.dart';

/// Kanten, Label-Chips und Karten eines [CanvasFrame] in Leinwand-Koordinaten.
class WorkflowCanvasScene extends StatelessWidget {
  const WorkflowCanvasScene({
    super.key,
    required this.frame,
    required this.selected,
    required this.onSelect,
    required this.onChoose,
    required this.onDrop,
  });

  final CanvasFrame frame;
  final NodeId? selected;
  final ValueChanged<WorkflowNode> onSelect;
  final ValueChanged<BausteinInsertion> onChoose;
  final void Function(BausteinChoice, BausteinInsertion) onDrop;

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: frame.size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WorkflowEdgesPainter(
                frame,
                Theme.of(context).colorScheme,
              ),
            ),
          ),
          for (final link in frame.links)
            if (_showsLabels(link))
              if (canvasLabelAnchor(frame, link) case final Offset anchor)
                Positioned(
                  left: anchor.dx,
                  top: anchor.dy,
                  child: Opacity(
                    opacity: frame.linkOpacityOf(link),
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: CanvasLabelStack(link: link),
                    ),
                  ),
                ),
          // Per ID geschlüsselt, damit eine Karte während des Übergangs
          // ihren Zustand behält, während sie gleitet oder ausblendet.
          for (final entry in frame.entries)
            Positioned.fromRect(
              key: ValueKey('canvas-entry-${entry.id}'),
              rect: frame.rectangles[entry.id]!,
              child: IgnorePointer(
                ignoring: frame.departing.contains(entry.id),
                child: Opacity(
                  opacity: frame.opacityOf(entry.id),
                  child: _CanvasEntryView(
                    entry: entry,
                    selected: selected,
                    onSelect: onSelect,
                    onChoose: onChoose,
                    onDrop: onDrop,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _showsLabels(CanvasLink link) =>
      link.labels.isNotEmpty &&
      (!link.isReturn || WorkflowCanvasOptions.showReturnEdges);
}

class _CanvasEntryView extends StatelessWidget {
  const _CanvasEntryView({
    required this.entry,
    required this.selected,
    required this.onSelect,
    required this.onChoose,
    required this.onDrop,
  });

  final CanvasEntry entry;
  final NodeId? selected;
  final ValueChanged<WorkflowNode> onSelect;
  final ValueChanged<BausteinInsertion> onChoose;
  final void Function(BausteinChoice, BausteinInsertion) onDrop;

  @override
  Widget build(BuildContext context) {
    final node = entry.node;
    return DragTarget<BausteinChoice>(
      onWillAcceptWithDetails: (_) => entry.canInsert,
      onAcceptWithDetails: (details) => onDrop(details.data, entry.insertion),
      builder: (context, candidates, _) => node == null
          ? CanvasPathInsertion(
              entry: entry,
              targeted: candidates.isNotEmpty,
              onPressed: () => onChoose(entry.insertion),
            )
          : AgentCursorAnchor(
              target: TaskBuilderCursorTargets.node(node.id),
              onActivate: () => onSelect(node),
              child: CompactWorkflowNode(
                node: node,
                selected: selected == node.id,
                targeted: candidates.isNotEmpty,
                onTap: () => onSelect(node),
              ),
            ),
    );
  }
}
