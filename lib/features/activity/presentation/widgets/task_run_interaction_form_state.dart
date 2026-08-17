import 'package:flutter/material.dart';

import '../../domain/entities/task_run.dart';
import 'task_run_dialog_input_submission.dart';

class TaskRunInteractionFormState {
  TaskRunInteractionFormState(TaskRun run)
    : outputController = TextEditingController(
        text: run.reviewOutput ?? run.finalOutput ?? '',
      ) {
    initializeDialogInput(run.dialogInputFields, controllers, values);
  }

  final formKey = GlobalKey<FormState>();
  final values = <String, Object?>{};
  final controllers = <String, TextEditingController>{};
  final TextEditingController outputController;

  void dispose() {
    outputController.dispose();
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }
}
