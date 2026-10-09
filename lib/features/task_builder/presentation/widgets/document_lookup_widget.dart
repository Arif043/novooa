import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
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
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.ui_datensatz_suchen.tr(),
              style: SyscatTheme.taskBody,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: config.collectionName,
              decoration: InputDecoration(
                labelText: LocaleKeys.ui_suche_in.tr(),
              ),
              onChanged: (value) => context
                  .read<TaskBuilderCubit>()
                  .updateDocumentLookupCollection(node.id, value),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.ui_wo.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
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
              label: Text(LocaleKeys.ui_bedingung_hinzufuegen.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
