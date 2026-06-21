import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'builder_panel.dart';

class WorkflowCanvas extends StatelessWidget {
  const WorkflowCanvas({
    super.key,
    required this.taskDefinition,
    required this.onNodeSelected,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<NodeId> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return BuilderPanel(
      title: taskDefinition.title,
      action: Text('${taskDefinition.nodes.length} Nodes'),
      child: ListView.separated(
        itemCount: taskDefinition.nodes.length,
        separatorBuilder: (context, index) => const _FlowConnector(),
        itemBuilder: (context, index) {
          final node = taskDefinition.nodes[index];
          return _WorkflowNodeTile(
            node: node,
            selected: node.id == taskDefinition.selectedNodeId,
            onTap: () => onNodeSelected(node.id),
          );
        },
      ),
    );
  }
}

class _WorkflowNodeTile extends StatelessWidget {
  const _WorkflowNodeTile({
    required this.node,
    required this.selected,
    required this.onTap,
  });

  final WorkflowNode node;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? SyscatTheme.primaryOrangeDark
        : SyscatTheme.borderStrong;
    return Semantics(
      button: true,
      selected: selected,
      label: '${node.title} auswählen',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? SyscatTheme.primaryOrangeHover
                : SyscatTheme.glassSurface,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(node.primitive.label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 32,
      child: Center(child: Icon(Icons.arrow_downward, size: 18)),
    );
  }
}
