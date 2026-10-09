import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
            Text(
              LocaleKeys.ui_datensatz_speichern.tr(),
              style: SyscatTheme.taskBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: config.collectionName,
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_speichere_in.tr(),
              ),
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
                  ? LocaleKeys.ui_new_record_created.tr()
                  : LocaleKeys.ui_matching_records_updated.tr(),
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
              label: Text(LocaleKeys.ui_bedingung_hinzufuegen.tr()),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.ui_felder.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
              label: Text(LocaleKeys.ui_feld_hinzufuegen.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
