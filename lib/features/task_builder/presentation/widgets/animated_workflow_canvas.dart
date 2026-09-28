import 'package:flutter/material.dart';

import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';
import 'workflow_canvas.dart';
import 'workflow_canvas_layout.dart';

class AnimatedWorkflowCanvas extends StatelessWidget {
  const AnimatedWorkflowCanvas({
    super.key,
    required this.graph,
    required this.selected,
    required this.isInspectorVisible,
    required this.onSelect,
    required this.onDrop,
    required this.onChoose,
  });

  static const _inspectorWidth = 560.0;

  final WorkflowGraph graph;
  final NodeId? selected;
  final bool isInspectorVisible;
  final ValueChanged<WorkflowNode> onSelect;
  final void Function(BausteinChoice, BausteinInsertion) onDrop;
  final ValueChanged<BausteinInsertion> onChoose;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOutCubic,
      tween: Tween(end: isInspectorVisible ? _inspectorWidth : 0),
      builder: (context, inspectorWidth, _) => WorkflowCanvas(
        graph: graph,
        inspectorWidth: inspectorWidth,
        selected: selected,
        onSelect: onSelect,
        onDrop: onDrop,
        onChoose: onChoose,
      ),
    );
  }
}
