import 'package:multiple_result/multiple_result.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/repositories/task_runner_repository.dart';
import '../datasources/local_genkit_task_client.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_execution_result_model.dart';

class LocalGenkitTaskRunnerRepository implements TaskRunnerRepository {
  const LocalGenkitTaskRunnerRepository(this._client);

  final LocalGenkitTaskClient _client;

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({required Task task, String context = ''}) async {
    try {
      final request = RunTaskDefinitionRequestModel(taskDefinition: task, context: context).toJson();
      final response = await _client.runTaskDefinition(request);
      final result = TaskExecutionResultModel.fromJson(response).toDomain();
      return Success(result);
    } on LocalGenkitConnectionException {
      return const Error(TaskExecutionFailure(TaskExecutionFailureKind.localServerUnavailable));
    } on LocalGenkitExecutionException {
      return const Error(TaskExecutionFailure(TaskExecutionFailureKind.executionFailed));
    } on TypeError {
      return const Error(TaskExecutionFailure(TaskExecutionFailureKind.invalidResponse));
    } catch (_) {
      return const Error(TaskExecutionFailure(TaskExecutionFailureKind.executionFailed));
    }
  }
}
