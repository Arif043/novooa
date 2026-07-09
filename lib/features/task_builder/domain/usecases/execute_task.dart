import 'package:multiple_result/multiple_result.dart';
import '../entities/task.dart';
import '../entities/task_execution_failure.dart';
import '../entities/task_run_start.dart';
import '../repositories/task_repository.dart';

class ExecuteTaskParams {
  const ExecuteTaskParams({required this.task, this.context = ''});

  final Task task;
  final String context;
}

class ExecuteTask {
  const ExecuteTask(this._repository);

  final TaskRepository _repository;

  Future<Result<TaskRunStart, TaskExecutionFailure>> call(
    ExecuteTaskParams params,
  ) async {
    return _repository.execute(task: params.task, context: params.context);
  }
}
