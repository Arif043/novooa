import '../../../../core/entities/unique_id.dart';

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
  final String? message;
}
