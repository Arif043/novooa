import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/media_input_submission.dart';
import '../../domain/entities/task_run.dart';
import '../../domain/entities/task_run_interaction.dart';
import 'task_run_dialog_input_form.dart';
import 'task_run_media_input_form.dart';

class TaskRunInteractionContent extends StatelessWidget {
  const TaskRunInteractionContent({
    super.key,
    required this.run,
    required this.formKey,
    required this.formValues,
    required this.controllers,
    required this.outputController,
    required this.mediaSubmission,
    required this.isPicking,
    required this.onFormValueChanged,
    required this.onPickMedia,
    required this.onClearMedia,
  });

  final TaskRun run;
  final GlobalKey<FormState> formKey;
  final Map<String, Object?> formValues;
  final Map<String, TextEditingController> controllers;
  final TextEditingController outputController;
  final MediaInputSubmission? mediaSubmission;
  final bool isPicking;
  final void Function(String name, Object? value) onFormValueChanged;
  final VoidCallback onPickMedia;
  final VoidCallback onClearMedia;

  @override
  Widget build(BuildContext context) {
    return switch (run.interaction?.type) {
      TaskRunInteractionType.dialogInput => _dialogInputForm(),
      TaskRunInteractionType.mediaInput => _mediaInputForm(),
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

  Widget _mediaInputForm() {
    final input = run.mediaInput;
    if (input == null) return const SizedBox.shrink();
    return TaskRunMediaInputForm(
      input: input,
      submission: mediaSubmission,
      isPicking: isPicking,
      onPick: onPickMedia,
      onClear: onClearMedia,
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
