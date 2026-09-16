import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'document_field_assignment_editor.dart';

class SaveDocumentWidget extends StatelessWidget {
  const SaveDocumentWidget({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final config = node.config as SaveDocumentNodeConfig;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datensatz speichern', style: SyscatTheme.taskBody),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              initialValue: config.collectionId,
              decoration: const InputDecoration(labelText: 'Speichere in'),
              onChanged: (value) => context
                  .read<TaskBuilderCubit>()
                  .updateSaveDocumentCollection(node.id, value),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DocumentSaveMode>(
              initialValue: config.mode,
              decoration: const InputDecoration(labelText: 'Aktion'),
              items: DocumentSaveMode.values.map(_modeItem).toList(),
              onChanged: (value) => _updateMode(context, value),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DocumentIdField(nodeId: node.id, config: config),
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

  DropdownMenuItem<DocumentSaveMode> _modeItem(DocumentSaveMode mode) {
    return DropdownMenuItem(value: mode, child: Text(mode.label));
  }

  void _updateMode(BuildContext context, DocumentSaveMode? mode) {
    if (mode == null) return;
    context.read<TaskBuilderCubit>().updateSaveDocumentMode(node.id, mode);
  }
}

class _DocumentIdField extends StatelessWidget {
  const _DocumentIdField({required this.nodeId, required this.config});

  final NodeId nodeId;
  final SaveDocumentNodeConfig config;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: config.documentId,
      decoration: InputDecoration(labelText: _label),
      onChanged: (value) =>
          context.read<TaskBuilderCubit>().updateSaveDocumentId(nodeId, value),
    );
  }

  String get _label {
    return config.mode == DocumentSaveMode.create
        ? 'Datensatz-ID (optional)'
        : 'Datensatz-ID';
  }
}

extension on DocumentSaveMode {
  String get label {
    return switch (this) {
      .create => 'Anlegen',
      .update => 'Aktualisieren',
      .upsert => 'Anlegen oder aktualisieren',
    };
  }
}
