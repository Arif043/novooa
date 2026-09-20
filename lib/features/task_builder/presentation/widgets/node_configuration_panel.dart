import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/workflow_primitive_labels.dart';
import 'baustein_palette.dart';
import 'node_graph_item.dart';

class NodeConfigurationPanel extends StatelessWidget {
  const NodeConfigurationPanel({
    super.key,
    required this.node,
    required this.onClose,
  });
  final WorkflowNode node;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      shadowColor: Colors.black26,
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
            child: Row(
              children: [
                Icon(
                  bausteinIcon(node.config.primitive),
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.config.primitive.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Konfiguration schließen',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SelectableText(
              'ID: ${node.id.value}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('configuration-scroll-${node.id.value}'),
              padding: const EdgeInsets.all(16),
              child: NodeGraphItem(
                key: ValueKey(node.id),
                node: node,
                configurationOnly: true,
                dragSourceNodeIds: const {},
                isSource: false,
                isDragActive: false,
                onDragStarted: () {},
                onDragEnded: () {},
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Änderungen werden automatisch gespeichert.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Baustein löschen',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    context.read<TaskBuilderCubit>().removeNode(node.id);
                    onClose();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
