import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/task_run_start.dart';

class TaskRunStartModel {
  const TaskRunStartModel({required this.runId, required this.taskId});

  final String runId;
  final String taskId;

  factory TaskRunStartModel.fromJson(Map<String, Object?> json) {
    return TaskRunStartModel(
      runId: json['runId'] as String? ?? '',
      taskId: json['taskId'] as String? ?? '',
    );
  }

  TaskRunStart toDomain() {
    return TaskRunStart(runId: UniqueId(runId), taskId: taskId);
  }
}
