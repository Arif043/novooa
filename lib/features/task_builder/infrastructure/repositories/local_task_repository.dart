import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_run_start.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_runner_datasource.dart';
import '../datasources/task_runner_datasource_log.dart';
import '../errors/task_runner_datasource_exception.dart';
import '../models/run_task_definition_request_model.dart';
import '../models/task_document_mapper.dart';
import '../models/task_run_start_model.dart';

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._client, this._runnerDatasource);

  final LocalRuntimeApiClient _client;
  final TaskRunnerDatasource _runnerDatasource;
  final TaskDocumentMapper _mapper = TaskDocumentMapper();

  @override
  Stream<List<Task>> watchTasks() => pollLocalRuntime(_loadTasks);

  @override
  Future<void> saveTask(Task task) {
    return _client.put(
      '/v1/tasks/${Uri.encodeComponent(task.id)}',
      _mapper.toDocument(task),
    );
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _client.delete('/v1/tasks/${Uri.encodeComponent(taskId)}');
  }

  @override
  Future<Result<TaskRunStart, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    logTaskRunnerDatasourceInfo('Lokale Runtime startet Aufgabe: ${task.id}');
    try {
      await saveTask(task);
      final response = await _runnerDatasource.runTaskDefinition(
        RunTaskDefinitionRequestModel(
          taskId: task.id,
          context: context,
        ).toJson(),
      );
      final taskRun = TaskRunStartModel.fromJson(response).toDomain();
      logTaskRunnerDatasourceInfo(
        'Lokale Runtime hat Aufgabe gestartet: ${task.id}, Run: ${taskRun.runId.value}',
      );
      return Success(taskRun);
    } on TaskRunnerDatasourceConnectionException catch (error, stackTrace) {
      _logExecutionFailure(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localServerUnavailable),
      );
    } on TaskRunnerDatasourceTimeoutException catch (error, stackTrace) {
      _logExecutionFailure(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localExecutionTimeout),
      );
    } on TaskRunnerDatasourceExecutionException catch (error, stackTrace) {
      _logExecutionFailure(error, stackTrace);
      return Error(TaskExecutionFailure.fromTaskRunFailure(error.failure));
    } on TypeError catch (error, stackTrace) {
      _logExecutionFailure(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.invalidResponse),
      );
    } catch (error, stackTrace) {
      _logExecutionFailure(error, stackTrace);
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
      );
    }
  }

  Future<List<Task>> _loadTasks() async {
    final response = await _client.get('/v1/tasks');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Die lokale Aufgabenliste ist ungültig.');
    }
    return items.whereType<Map>().map(_taskFromJson).toList(growable: false);
  }

  Task _taskFromJson(Map<dynamic, dynamic> value) {
    final data = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    return _mapper.fromMap(data, fallbackId: data['id'] as String? ?? '');
  }

  void _logExecutionFailure(Object error, StackTrace stackTrace) {
    logTaskRunnerDatasourceException(
      message: 'Lokale Aufgabenausführung ist fehlgeschlagen.',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
