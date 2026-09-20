import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'node_graph.dart';

class ForEachWidget extends StatelessWidget {
  const ForEachWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as ForEachNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Für jedes Element', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: config.itemsTemplate,
            decoration: const InputDecoration(
              labelText: 'Liste',
              hintText: '{{erkennung.regions}}',
            ),
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateForEachItems(node.id, value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: config.itemsPointer,
            decoration: const InputDecoration(
              labelText: 'Elemente aus',
              hintText: 'Leer für die gesamte Liste, z. B. /regions',
            ),
            onChanged: (value) => context
                .read<TaskBuilderCubit>()
                .updateForEachPointer(node.id, value),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Der Pfad wählt innerhalb der angegebenen Liste die Elemente aus.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Für jedes gefundene Element', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'In diesem Unterplan ist {{iteration.value}} der aktuelle Wert.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          NodeGraph(
            nodes: config.graph.nodes,
            onPrimitiveAccepted: (primitive) =>
                context.read<TaskBuilderCubit>().addNodeToForEachGraph(
                  forEachNodeId: node.id,
                  primitive: primitive,
                ),
          ),
        ],
      ),
    );
  }
}
