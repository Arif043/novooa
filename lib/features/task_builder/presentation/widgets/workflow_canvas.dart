import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import 'flow_connector.dart';
import 'node_card.dart';

/// Scrollbarer vertikaler Flow der Bausteine.
///
/// Bewusst rahmenlos: das umgebende [WorkflowBuilderView] zeichnet
/// bei Bedarf den Trennstrich zum Inspector. Header (`CanvasHeader`)
/// und „Baustein hinzufügen"-Pille (`AddNodeButton`) werden vom
/// Builder-View eingesetzt — diese Komponente kennt nur die Knoten.
class WorkflowCanvas extends StatelessWidget {
  const WorkflowCanvas({
    super.key,
    required this.taskDefinition,
    required this.onNodeSelected,
    required this.onNodeDeleted,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<NodeId> onNodeSelected;
  final ValueChanged<NodeId> onNodeDeleted;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: taskDefinition.nodes.length,
      separatorBuilder: (context, _) => const FlowConnector(),
      itemBuilder: (context, index) {
        final node = taskDefinition.nodes[index];
        return NodeCard(
          node: node,
          selected: node.id == taskDefinition.selectedNodeId,
          isStart: index == 0,
          onTap: () => onNodeSelected(node.id),
          onDelete: () => onNodeDeleted(node.id),
        );
      },
    );
  }
}