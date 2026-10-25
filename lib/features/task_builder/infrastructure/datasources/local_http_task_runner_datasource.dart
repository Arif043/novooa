import 'dart:async';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/task_run_failure.dart';
import '../errors/task_runner_datasource_exception.dart';
import 'task_runner_datasource.dart';

class LocalHttpTaskRunnerDatasource implements TaskRunnerDatasource {
  const LocalHttpTaskRunnerDatasource(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    try {
      return await _client.post('/v1/task-runs', request);
    } on TimeoutException catch (error) {
      throw TaskRunnerDatasourceTimeoutException(
        endpoint: '/v1/task-runs',
        timeout: const Duration(seconds: 15),
        cause: error,
      );
    } on WorkspaceConnectionException catch (error) {
      throw TaskRunnerDatasourceConnectionException(
        endpoint: '/v1/task-runs',
        cause: error,
      );
    } on WorkspaceHttpException catch (error) {
      throw TaskRunnerDatasourceExecutionException(
        endpoint: '/v1/task-runs',
        statusCode: error.statusCode,
        responseBody: error.message,
        failure: TaskRunFailure.fromCode(error.errorCode, error.message),
      );
    }
  }
}
