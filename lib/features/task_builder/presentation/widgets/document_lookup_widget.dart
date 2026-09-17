import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'document_lookup_filter_editor.dart';

class DocumentLookupWidget extends StatelessWidget {
  const DocumentLookupWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as DocumentLookupNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datensatz suchen', style: SyscatTheme.taskBody),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: config.collectionName,
              decoration: const InputDecoration(labelText: 'Suche in'),
              onChanged: (value) => context
                  .read<TaskBuilderCubit>()
                  .updateDocumentLookupCollection(node.id, value),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Wo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < config.filters.length; index++) ...[
              DocumentLookupFilterEditor(
                key: ValueKey('document-lookup-filter-${node.id.value}-$index'),
                nodeId: node.id,
                index: index,
                filter: config.filters[index],
                canRemove: config.filters.length > 1,
                onChanged: (filter) => context
                    .read<TaskBuilderCubit>()
                    .updateDocumentLookupFilter(node.id, index, filter),
                onRemove: () => context
                    .read<TaskBuilderCubit>()
                    .removeDocumentLookupFilter(node.id, index),
              ),
              if (index < config.filters.length - 1)
                const Divider(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addDocumentLookupFilter(node.id),
              icon: const Icon(Icons.add),
              label: const Text('Bedingung hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
