import '../../../../core/entities/unique_id.dart';

enum TaskActivityTarget { task, node }

enum TaskActivityStatus { started, succeeded, failed, skipped, waiting }

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
    this.outputs = const {},
    this.stdout = '',
    this.stderr = '',
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
  final Map<String, Object?> outputs;

  /// Was der Baustein auf stdout und stderr ausgegeben hat (Script-Baustein); leer, wenn nichts.
  final String stdout;
  final String stderr;

  bool get hasConsoleOutput => stdout.isNotEmpty || stderr.isNotEmpty;
}
