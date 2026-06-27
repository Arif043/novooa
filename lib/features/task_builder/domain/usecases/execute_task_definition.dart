import 'package:multiple_result/multiple_result.dart';

import '../../../../core/domain/unique_id.dart';
import '../../../activity/domain/usecases/track_task_execution.dart';
import '../entities/task_definition.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_execution_result.dart';
import '../repositories/task_runner_repository.dart';

class ExecuteTaskDefinitionParams {
  const ExecuteTaskDefinitionParams({required this.taskDefinition, this.context = ''});

  final TaskDefinition taskDefinition;
  final String context;
}

class ExecuteTaskDefinition {
  const ExecuteTaskDefinition(this._repository, {TrackTaskExecution? tracker}) : _tracker = tracker;

  final TaskRunnerRepository _repository;
  final TrackTaskExecution? _tracker;

  Future<Result<TaskExecutionResult, TaskExecutionFailure>> call(ExecuteTaskDefinitionParams params) async {
    final runId = await _tracker?.started(params.taskDefinition, params.context);
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
      (result) => tracker.succeeded(runId: runId, taskDefinition: params.taskDefinition, result: result),
      (failure) => tracker.failed(runId: runId, taskDefinition: params.taskDefinition, failure: failure),
    );
  }
}
