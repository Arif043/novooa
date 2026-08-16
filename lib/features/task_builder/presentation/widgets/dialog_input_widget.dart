import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'dialog_input_field_editor.dart';

class DialogInputWidget extends StatelessWidget {
  const DialogInputWidget({super.key, required this.node});

  final WorkflowNode node;

  DialogInputNodeConfig get _config {
    return node.config as DialogInputNodeConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: SyscatTheme.nodePanelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formulareingabe', style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            initialValue: _config.instruction,
            decoration: const InputDecoration(
              hintText: 'Hinweis für die Eingabe',
            ),
            onChanged: (value) => _update(
              context,
              (config) => config.copyWith(instruction: value),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < _config.fields.length; index++) ...[
            DialogInputFieldEditor(
              field: _config.fields[index],
              canRemove: _config.fields.length > 1,
              onChanged: (field) => _update(
                context,
                (config) => config.updateField(index, field),
              ),
              onRemove: () =>
                  _update(context, (config) => config.removeField(index)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Feld hinzufügen',
              onPressed: () => _update(context, (config) => config.addField()),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ),
        ],
      ),
    );
  }

  void _update(
    BuildContext context,
    DialogInputNodeConfig Function(DialogInputNodeConfig config) update,
  ) {
    context.read<TaskBuilderCubit>().updateDialogInput(node.id, update);
  }
}
