import '../../../../core/entities/unique_id.dart';

import 'task_run_dialog_input_field.dart';

enum TaskRunStatus {
  queued,
  running,
  waitingForApproval,
  rejected,
  succeeded,
  failed;

  static TaskRunStatus fromName(String name) {
    return TaskRunStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => TaskRunStatus.queued,
    );
  }
}

enum TaskRunReviewDecision { approve, reject }

class TaskRun {
  const TaskRun({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.status,
    required this.updatedAt,
    this.createdAt,
    this.waitingNodeId,
    this.finalOutput,
    this.reviewInstruction,
    this.reviewOutput,
    this.dialogInputFields = const [],
    this.message,
  });

  final UniqueId id;
  final String taskId;
  final String taskTitle;
  final TaskRunStatus status;
  final DateTime updatedAt;
  final DateTime? createdAt;
  final String? waitingNodeId;
  final String? finalOutput;
  final String? reviewInstruction;
  final String? reviewOutput;
  final List<TaskRunDialogInputField> dialogInputFields;
  final String? message;

  bool get requiresDialogInput => dialogInputFields.isNotEmpty;
}
