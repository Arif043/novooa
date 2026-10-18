import 'package:flutter/material.dart';

import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';
import 'workflow_canvas_frame.dart';
import 'workflow_canvas_layout.dart';
import 'workflow_canvas_scene.dart';

/// Dauer, in der Karten und Kanten nach einer Änderung gleiten bzw. ein- und
/// ausblenden.
const canvasLayoutTransitionDuration = Duration(milliseconds: 350);

/// Zeigt [layout]; ändert es sich, spielt die Szene den Übergang vom alten
/// zum neuen Layout ab ([CanvasFrame]) statt zu springen.
class AnimatedWorkflowCanvasScene extends StatefulWidget {
  const AnimatedWorkflowCanvasScene({
    super.key,
    required this.layout,
    required this.selected,
    required this.onSelect,
    required this.onChoose,
    required this.onDrop,
  });

  final WorkflowCanvasLayout layout;
  final NodeId? selected;
  final ValueChanged<WorkflowNode> onSelect;
  final ValueChanged<BausteinInsertion> onChoose;
  final void Function(BausteinChoice, BausteinInsertion) onDrop;

  @override
  State<AnimatedWorkflowCanvasScene> createState() =>
      _AnimatedWorkflowCanvasSceneState();
}

class _AnimatedWorkflowCanvasSceneState
    extends State<AnimatedWorkflowCanvasScene>
    with SingleTickerProviderStateMixin {
  late final _transition = AnimationController(
    vsync: this,
    duration: canvasLayoutTransitionDuration,
    value: 1,
  )..addStatusListener(_dropPreviousLayout);
  WorkflowCanvasLayout? _previousLayout;

  @override
  void didUpdateWidget(AnimatedWorkflowCanvasScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.layout, widget.layout)) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _previousLayout = oldWidget.layout;
    _transition.forward(from: 0);
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transition,
      builder: (context, _) => WorkflowCanvasScene(
        frame: _frame(),
        selected: widget.selected,
        onSelect: widget.onSelect,
        onChoose: widget.onChoose,
        onDrop: widget.onDrop,
      ),
    );
  }

  CanvasFrame _frame() {
    final previous = _previousLayout;
    if (previous == null) return CanvasFrame.of(widget.layout);
    final progress = Curves.easeInOutCubic.transform(_transition.value);
    return CanvasFrame.between(previous, widget.layout, progress);
  }

  void _dropPreviousLayout(AnimationStatus status) {
    if (status != AnimationStatus.completed || _previousLayout == null) return;
    setState(() => _previousLayout = null);
  }
}
