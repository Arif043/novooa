import 'package:multiple_result/multiple_result.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_execution_result.dart';
import '../../domain/repositories/task_runner_repository.dart';
import '../datasources/task_client.dart';
import '../datasources/task_client_log.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_execution_result_model.dart';

class TaskRunnerRepositoryImpl implements TaskRunnerRepository {
  const TaskRunnerRepositoryImpl(this._client);

  final TaskClient _client;

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    _logStart(task);
    try {
      return Success(await _executeTask(task: task, context: context));
    } on TaskClientConnectionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.localServerUnavailable);
    } on TaskClientTimeoutException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.localExecutionTimeout);
    } on TaskClientExecutionException catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.executionFailed);
    } on TypeError catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.invalidResponse);
    } catch (error, stackTrace) {
      _logException(error, stackTrace);
      return _failure(TaskExecutionFailureKind.executionFailed);
    }
  }

  Future<TaskExecutionResult> _executeTask({
    required Task task,
    required String context,
  }) async {
    final response = await _client.runTaskDefinition(
      RunTaskDefinitionRequestModel(
        taskDefinition: task,
        context: context,
      ).toJson(),
    );
    logTaskClientInfo('Repository hat Task erfolgreich ausgeführt: ${task.id}');
    return TaskExecutionResultModel.fromJson(response).toDomain();
  }

  Result<TaskExecutionResult, TaskExecutionFailure> _failure(
    TaskExecutionFailureKind kind,
  ) {
    return Error(TaskExecutionFailure(kind));
  }

  void _logStart(Task task) {
    logTaskClientInfo(
      'Repository startet Task-Ausführung: ${task.title} (${task.id})',
    );
  }

  void _logException(Object error, StackTrace stackTrace) {
    logTaskClientException(
      message: 'Task-Ausführung wurde als Fehler gemappt.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
