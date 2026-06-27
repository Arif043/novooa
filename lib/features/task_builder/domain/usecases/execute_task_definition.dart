import 'package:multiple_result/multiple_result.dart';

import '../../../../core/entities/unique_id.dart';
import '../../../activity/domain/entities/task_activity.dart';
import '../../../activity/domain/usecases/track_task_execution.dart';
import '../entities/task.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_execution_result.dart';
import '../repositories/task_runner_repository.dart';

class ExecuteTaskDefinitionParams {
  const ExecuteTaskDefinitionParams({required this.taskDefinition, this.context = ''});

  final Task taskDefinition;
  final String context;
}

class ExecuteTaskDefinition {
  const ExecuteTaskDefinition(this._repository, {TrackTaskExecution? tracker}) : _tracker = tracker;

  final TaskRunnerRepository _repository;
  final TrackTaskExecution? _tracker;

  Future<Result<TaskExecutionResult, TaskExecutionFailure>> call(ExecuteTaskDefinitionParams params) async {
    final runId = await _tracker?.started(_trackStart(params));
    final taskExecutionOrFailure = await _repository.execute(
      taskDefinition: params.taskDefinition,
      context: params.context,
    );
    await _trackResult(params, taskExecutionOrFailure, runId);
    return taskExecutionOrFailure;
  }

  Future<void> _trackResult(
    ExecuteTaskDefinitionParams params,
    Result<TaskExecutionResult, TaskExecutionFailure> taskExecutionOrFailure,
    UniqueId? runId,
  ) async {
    final tracker = _tracker;
    if (tracker == null || runId == null) return;
    await taskExecutionOrFailure.when(
      (result) => tracker.succeeded(runId: runId, success: _trackSuccess(params.taskDefinition, result)),
      (failure) => tracker.failed(runId: runId, failure: _trackFailure(params.taskDefinition, failure)),
    );
  }

  TrackTaskStart _trackStart(ExecuteTaskDefinitionParams params) {
    return TrackTaskStart(
      taskId: params.taskDefinition.id,
      taskTitle: params.taskDefinition.title,
      input: params.context,
    );
  }

  TrackTaskSuccess _trackSuccess(Task taskDefinition, TaskExecutionResult result) {
    return TrackTaskSuccess(
      taskId: taskDefinition.id,
      taskTitle: taskDefinition.title,
      output: result.finalOutput,
      nodes: result.nodeResults.map(_trackNode).toList(),
    );
  }

  TrackTaskFailure _trackFailure(Task taskDefinition, TaskExecutionFailure failure) {
    return TrackTaskFailure(taskId: taskDefinition.id, taskTitle: taskDefinition.title, message: failure.message);
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
