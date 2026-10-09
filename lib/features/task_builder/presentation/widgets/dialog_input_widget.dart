import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'dialog_input_field_editor.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

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
      decoration: SyscatTheme.nodePanelDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(LocaleKeys.ui_formulareingabe.tr(), style: SyscatTheme.taskBody),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: _config.instruction,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_hinweis_fuer_die_eingabe.tr(),
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
              onChanged: (field) =>
                  context.read<TaskBuilderCubit>().updateDialogInputField(
                    nodeId: node.id,
                    fieldIndex: index,
                    field: field,
                  ),
              onRemove: () =>
                  _update(context, (config) => config.removeField(index)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: LocaleKeys.ui_feld_hinzufuegen.tr(),
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
