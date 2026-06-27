import 'package:multiple_result/multiple_result.dart';

import '../entities/task_definition.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_execution_result.dart';

abstract interface class TaskRunnerRepository {
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required TaskDefinition taskDefinition,
    String context,
  });
}
