import 'package:multiple_result/multiple_result.dart';

import '../entities/task_definition.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_execution_result.dart';
import '../repositories/task_runner_repository.dart';

class ExecuteTaskDefinitionParams {
  const ExecuteTaskDefinitionParams({
    required this.taskDefinition,
    this.context = '',
  });

  final TaskDefinition taskDefinition;
  final String context;
}

class ExecuteTaskDefinition {
  const ExecuteTaskDefinition(this._repository);

  final TaskRunnerRepository _repository;

  Future<Result<TaskExecutionResult, TaskExecutionFailure>> call(
    ExecuteTaskDefinitionParams params,
  ) {
    return _repository.execute(
      taskDefinition: params.taskDefinition,
      context: params.context,
    );
  }
}
