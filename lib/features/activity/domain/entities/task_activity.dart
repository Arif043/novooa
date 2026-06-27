import '../../../../core/domain/unique_id.dart';

enum TaskActivityTarget { task, node }

enum TaskActivityStatus { started, succeeded, failed, skipped }

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.runId,
    required this.taskId,
    required this.taskTitle,
    required this.target,
    required this.status,
    required this.occurredAt,
    this.nodeId,
    this.primitive,
    this.input,
    this.output,
    this.message,
  });

  final UniqueId id;
  final UniqueId runId;
  final String taskId;
  final String taskTitle;
  final TaskActivityTarget target;
  final TaskActivityStatus status;
  final DateTime occurredAt;
  final String? nodeId;
  final String? primitive;
  final String? input;
  final String? output;
  final String? message;
}
