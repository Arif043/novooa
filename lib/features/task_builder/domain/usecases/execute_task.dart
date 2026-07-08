import 'package:multiple_result/multiple_result.dart';
import '../../../../core/entities/unique_id.dart';
import '../../../activity/domain/entities/task_activity.dart';
import '../../../activity/domain/usecases/track_task_execution.dart';
import '../entities/task.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_execution_result.dart';
import '../repositories/task_repository.dart';

class ExecuteTaskParams {
  const ExecuteTaskParams({required this.task, this.context = ''});

  final Task task;
  final String context;
}

class ExecuteTask {
  const ExecuteTask(this._repository, {this.tracker});

  final TaskRepository _repository;
  final TrackTaskExecution? tracker;

  Future<Result<TaskExecutionResult, TaskExecutionFailure>> call(
    ExecuteTaskParams params,
  ) async {
    final runId = await tracker?.started(_trackStart(params));
    final taskExecutionOrFailure = await _repository.execute(
      task: params.task,
      context: params.context,
    );
    await _trackResult(params, taskExecutionOrFailure, runId);
    return taskExecutionOrFailure;
  }

  Future<void> _trackResult(
    ExecuteTaskParams params,
    Result<TaskExecutionResult, TaskExecutionFailure> taskExecutionOrFailure,
    UniqueId? runId,
  ) async {
    final trackerOrNull = tracker;
    if (trackerOrNull == null || runId == null) return;
    await taskExecutionOrFailure.when(
      (result) => trackerOrNull.succeeded(
        runId: runId,
        success: _trackSuccess(params.task, result),
      ),
      (failure) => trackerOrNull.failed(
        runId: runId,
        failure: _trackFailure(params.task, failure),
      ),
    );
  }

  TrackTaskStart _trackStart(ExecuteTaskParams params) {
    return TrackTaskStart(
      taskId: params.task.id,
      taskTitle: params.task.title,
      input: params.context,
    );
  }

  TrackTaskSuccess _trackSuccess(
    Task taskDefinition,
    TaskExecutionResult result,
  ) {
    return TrackTaskSuccess(
      taskId: taskDefinition.id,
      taskTitle: taskDefinition.title,
      output: result.finalOutput,
      nodes: result.nodeResults.map(_trackNode).toList(),
    );
  }

  TrackTaskFailure _trackFailure(
    Task taskDefinition,
    TaskExecutionFailure failure,
  ) {
    return TrackTaskFailure(
      taskId: taskDefinition.id,
      taskTitle: taskDefinition.title,
      message: failure.message,
    );
  }

  TrackNodeActivity _trackNode(NodeExecutionResult result) {
    return TrackNodeActivity(
      nodeId: result.nodeId.value,
      primitive: result.primitive.name,
      status: _nodeStatus(result),
      output: result.output,
      message: result.message,
    );
  }

  TaskActivityStatus _nodeStatus(NodeExecutionResult result) {
    return switch (result.status) {
      NodeExecutionStatus.executed => TaskActivityStatus.succeeded,
      NodeExecutionStatus.skipped => TaskActivityStatus.skipped,
    };
  }
}
