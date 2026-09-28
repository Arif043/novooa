import 'package:flutter/material.dart';
import '../../domain/entities/workflow_node.dart';
import 'node_configuration_panel.dart';

class AnimatedNodeConfigurationPanel extends StatelessWidget {
  const AnimatedNodeConfigurationPanel({
    super.key,
    required this.node,
    required this.isVisible,
    required this.onClose,
    required this.onDismissed,
  });

  final WorkflowNode node;
  final bool isVisible;
  final VoidCallback onClose;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(1.04, 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      onEnd: isVisible ? null : onDismissed,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: NodeConfigurationPanel(
            key: ValueKey(node.id),
            node: node,
            onClose: onClose,
          ),
        ),
      ),
    );
  }
}
