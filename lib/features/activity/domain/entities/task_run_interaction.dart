import 'task_run_dialog_input_field.dart';

enum TaskRunInteractionType {
  approval,
  dialogInput;

  static TaskRunInteractionType fromName(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => TaskRunInteractionType.approval,
    );
  }
}

class TaskRunInteraction {
  const TaskRunInteraction({
    required this.type,
    required this.instruction,
    this.dialogInputFields = const [],
  });

  final TaskRunInteractionType type;
  final String instruction;
  final List<TaskRunDialogInputField> dialogInputFields;
}
