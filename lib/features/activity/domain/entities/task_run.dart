import '../../../../core/entities/unique_id.dart';

import 'task_run_dialog_input_field.dart';
import 'task_run_interaction.dart';
import 'task_run_media_input.dart';

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
    this.reviewOutput,
    this.interaction,
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
  final String? reviewOutput;
  final TaskRunInteraction? interaction;
  final String? message;

  String? get reviewInstruction => interaction?.instruction;

  List<TaskRunDialogInputField> get dialogInputFields {
    return interaction?.dialogInputFields ?? const [];
  }

  TaskRunMediaInput? get mediaInput => interaction?.mediaInput;

  bool get requiresDialogInput {
    return interaction?.type == TaskRunInteractionType.dialogInput;
  }

  bool get requiresMediaInput {
    return interaction?.type == TaskRunInteractionType.mediaInput;
  }
}
