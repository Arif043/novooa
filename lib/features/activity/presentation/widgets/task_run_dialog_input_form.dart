import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run_dialog_input_field.dart';
import 'task_run_dialog_input_field_control.dart';

class TaskRunDialogInputForm extends StatelessWidget {
  const TaskRunDialogInputForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.controllers,
    required this.values,
    required this.onValueChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<TaskRunDialogInputField> fields;
  final Map<String, TextEditingController> controllers;
  final Map<String, Object?> values;
  final void Function(String name, Object? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          for (final field in fields) ...[
            TaskRunDialogInputFieldControl(
              field: field,
              controller: controllers[field.name],
              value: values[field.name],
              onValueChanged: onValueChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
