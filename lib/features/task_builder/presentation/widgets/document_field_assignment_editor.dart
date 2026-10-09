import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import 'template_expression_scope.dart';
import 'template_expression_text_field.dart';

class DocumentFieldAssignmentEditor extends StatelessWidget {
  const DocumentFieldAssignmentEditor({
    super.key,
    required this.nodeId,
    required this.index,
    required this.assignment,
    required this.canRemove,
  });

  final NodeId nodeId;
  final int index;
  final DocumentFieldAssignment assignment;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: LocaleKeys.ui_field_mapping_number.tr(
        namedArgs: {'number': '${index + 1}'},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            initialValue: assignment.field,
            decoration: InputDecoration(labelText: LocaleKeys.ui_feld.tr()),
            onChanged: (value) => _update(context, field: value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TemplateExpressionTextField(
            value: assignment.value,
            suggestions: TemplateExpressionScope.suggestionsOf(context),
            decoration: InputDecoration(labelText: LocaleKeys.ui_wert.tr()),
            onChanged: (value) => _update(context, value: value),
          ),
          if (canRemove)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: LocaleKeys.ui_feld_entfernen.tr(),
                onPressed: () => context
                    .read<TaskBuilderCubit>()
                    .removeSaveDocumentField(nodeId, index),
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ),
        ],
      ),
    );
  }

  void _update(BuildContext context, {String? field, String? value}) {
    context.read<TaskBuilderCubit>().updateSaveDocumentField(
      nodeId,
      index,
      assignment.copyWith(field: field, value: value),
    );
  }
}
