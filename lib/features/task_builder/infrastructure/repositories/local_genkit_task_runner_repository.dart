import 'package:multiple_result/multiple_result.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/repositories/task_runner_repository.dart';
import '../datasources/local_genkit_task_client.dart';
import '../datasources/local_genkit_log.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_execution_result_model.dart';

class LocalGenkitTaskRunnerRepository implements TaskRunnerRepository {
  const LocalGenkitTaskRunnerRepository(this._client);

  final LocalGenkitTaskClient _client;

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    logLocalGenkitInfo(
      'Repository startet Task-Ausführung: ${task.title} (${task.id})',
    );
    try {
      final request = RunTaskDefinitionRequestModel(
        taskDefinition: task,
        context: context,
      ).toJson();
      final response = await _client.runTaskDefinition(request);
      final result = TaskExecutionResultModel.fromJson(response).toDomain();
      logLocalGenkitInfo(
        'Repository hat Task erfolgreich ausgeführt: ${task.id}',
      );
      return Success(result);
    } on LocalGenkitConnectionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localServerUnavailable),
      );
    } on LocalGenkitTimeoutException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localExecutionTimeout),
      );
    } on LocalGenkitExecutionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
      );
    } on TypeError catch (error, stackTrace) {
      _logException(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.invalidResponse),
      );
    } catch (error, stackTrace) {
      _logException(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
      );
    }
  }

  void _logException(Object error, StackTrace stackTrace) {
    logLocalGenkitException(
      message: 'Task-Ausführung wurde als Fehler gemappt.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
