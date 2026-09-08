import 'package:multiple_result/multiple_result.dart';

import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_execution_failure.dart';
import '../../domain/entities/task_run_start.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_runner_datasource.dart';
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
    try {
      await saveTask(task);
      final response = await _runnerDatasource.runTaskDefinition(
        RunTaskDefinitionRequestModel(
          taskId: task.id,
          context: context,
        ).toJson(),
      );
      return Success(TaskRunStartModel.fromJson(response).toDomain());
    } on TaskRunnerDatasourceConnectionException {
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localServerUnavailable),
      );
    } on TaskRunnerDatasourceTimeoutException {
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.localExecutionTimeout),
      );
    } on TaskRunnerDatasourceExecutionException {
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.executionFailed),
      );
    } on TypeError {
      return const Error(
        TaskExecutionFailure(TaskExecutionFailureKind.invalidResponse),
      );
    } catch (_) {
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
}
