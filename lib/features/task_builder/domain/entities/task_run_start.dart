import '../../../../core/entities/unique_id.dart';

class TaskRunStart {
  const TaskRunStart({required this.runId, required this.taskId});

  final UniqueId runId;
  final String taskId;
}
