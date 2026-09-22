import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'document_field_assignment_editor.dart';
import 'document_lookup_filter_editor.dart';

class SaveDocumentWidget extends StatelessWidget {
  const SaveDocumentWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as SaveDocumentNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datensatz speichern', style: SyscatTheme.taskBody),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: config.collectionName,
              decoration: const InputDecoration(labelText: 'Speichere in'),
              onChanged: (value) => context
                  .read<TaskBuilderCubit>()
                  .updateSaveDocumentCollection(node.id, value),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              config.filters.isEmpty
                  ? 'Modus: Anlegen'
                  : 'Modus: Aktualisieren oder anlegen',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              config.filters.isEmpty
                  ? 'Ein neuer Datensatz wird angelegt.'
                  : 'Passende Datensätze werden aktualisiert. Ohne Treffer wird ein neuer angelegt.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < config.filters.length; index++) ...[
              DocumentLookupFilterEditor(
                key: ValueKey('save-document-filter-${node.id.value}-$index'),
                nodeId: node.id,
                index: index,
                filter: config.filters[index],
                canRemove: true,
                onChanged: (filter) => context
                    .read<TaskBuilderCubit>()
                    .updateSaveDocumentFilter(node.id, index, filter),
                onRemove: () => context
                    .read<TaskBuilderCubit>()
                    .removeSaveDocumentFilter(node.id, index),
              ),
              if (index < config.filters.length - 1)
                const Divider(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addSaveDocumentFilter(node.id),
              icon: const Icon(Icons.add),
              label: const Text('Bedingung hinzufügen'),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Felder', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < config.fields.length; index++) ...[
              DocumentFieldAssignmentEditor(
                key: ValueKey('save-document-field-${node.id.value}-$index'),
                nodeId: node.id,
                index: index,
                assignment: config.fields[index],
                canRemove: config.fields.length > 1,
              ),
              if (index < config.fields.length - 1)
                const Divider(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context
                  .read<TaskBuilderCubit>()
                  .addSaveDocumentField(node.id),
              icon: const Icon(Icons.add),
              label: const Text('Feld hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }
}
