import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/entities/task_run_interaction.dart';
import 'task_run_dialog_input_form.dart';

class TaskRunInteractionContent extends StatelessWidget {
  const TaskRunInteractionContent({
    super.key,
    required this.run,
    required this.formKey,
    required this.formValues,
    required this.controllers,
    required this.outputController,
    required this.onFormValueChanged,
  });

  final TaskRun run;
  final GlobalKey<FormState> formKey;
  final Map<String, Object?> formValues;
  final Map<String, TextEditingController> controllers;
  final TextEditingController outputController;
  final void Function(String name, Object? value) onFormValueChanged;

  @override
  Widget build(BuildContext context) {
    return switch (run.interaction?.type) {
      TaskRunInteractionType.dialogInput => _dialogInputForm(),
      _ => _reviewOutputField(),
    };
  }

  Widget _dialogInputForm() {
    return TaskRunDialogInputForm(
      formKey: formKey,
      fields: run.dialogInputFields,
      controllers: controllers,
      values: formValues,
      onValueChanged: onFormValueChanged,
    );
  }

  Widget _reviewOutputField() {
    return TextField(
      controller: outputController,
      minLines: 8,
      maxLines: 14,
      decoration: const InputDecoration(labelText: 'Output'),
    );
  }

  static Widget withInstruction({
    required TaskRun run,
    required Widget content,
  }) {
    final instruction = run.reviewInstruction?.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          instruction?.isNotEmpty == true
              ? instruction!
              : 'Prüfe das Ergebnis und gib es frei.',
        ),
        const SizedBox(height: AppSpacing.lg),
        content,
      ],
    );
  }
}
