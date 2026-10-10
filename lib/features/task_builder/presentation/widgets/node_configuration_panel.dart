import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
    this.fullBleed = false,
  });
  final WorkflowNode node;
  final VoidCallback onClose;

  /// Mobil: füllt den Bereich ohne Rand, Rundung und Innenabstand der Inhalte.
  final bool fullBleed;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: fullBleed ? 0 : 8,
      shadowColor: colors.shadow.withValues(alpha: .12),
      color: colors.surface,
      borderRadius: fullBleed ? BorderRadius.zero : BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    bausteinIcon(node.config.primitive),
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.config.primitive.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.ui_konfiguration_schliessen.tr(),
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
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
              padding: EdgeInsets.all(fullBleed ? 0 : 24),
              child: NodeGraphItem(
                key: ValueKey(node.id),
                node: node,
                configurationOnly: true,
                sectionPadding: fullBleed
                    ? const EdgeInsets.symmetric(horizontal: 24)
                    : EdgeInsets.zero,
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
                Expanded(
                  child: Text(
                    LocaleKeys.ui_aenderungen_werden_automatisch_gespeichert
                        .tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  tooltip: LocaleKeys.ui_baustein_loeschen.tr(),
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
