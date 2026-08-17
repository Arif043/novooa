import 'task_run_dialog_input_field.dart';
import 'task_run_media_input.dart';

enum TaskRunInteractionType {
  approval,
  dialogInput,
  mediaInput;

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
    this.mediaInput,
  });

  final TaskRunInteractionType type;
  final String instruction;
  final List<TaskRunDialogInputField> dialogInputFields;
  final TaskRunMediaInput? mediaInput;
}
