import 'dart:async';

import '../../../../core/network/local_runtime_api_client.dart';
import 'task_runner_datasource.dart';

class LocalHttpTaskRunnerDatasource implements TaskRunnerDatasource {
  const LocalHttpTaskRunnerDatasource(this._client);

  final LocalRuntimeApiClient _client;

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
    } on LocalRuntimeConnectionException catch (error) {
      throw TaskRunnerDatasourceConnectionException(
        endpoint: '/v1/task-runs',
        cause: error,
      );
    } on LocalRuntimeHttpException catch (error) {
      throw TaskRunnerDatasourceExecutionException(
        endpoint: '/v1/task-runs',
        statusCode: error.statusCode,
        responseBody: error.message,
      );
    }
  }
}
