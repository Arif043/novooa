import '../../domain/entities/task_run_failure.dart';

class TaskRunnerDatasourceConnectionException implements Exception {
  const TaskRunnerDatasourceConnectionException({this.endpoint, this.cause});

  final String? endpoint;
  final Object? cause;

  @override
  String toString() =>
      'TaskRunnerDatasourceConnectionException(endpoint: $endpoint, cause: $cause)';
}

class TaskRunnerDatasourceTimeoutException implements Exception {
  const TaskRunnerDatasourceTimeoutException({
    required this.endpoint,
    required this.timeout,
    this.cause,
  });

  final String endpoint;
  final Duration timeout;
  final Object? cause;

  @override
  String toString() =>
      'TaskRunnerDatasourceTimeoutException(endpoint: $endpoint, timeout: $timeout, cause: $cause)';
}

class TaskRunnerDatasourceExecutionException implements Exception {
  const TaskRunnerDatasourceExecutionException({
    this.endpoint,
    this.statusCode,
    this.responseBody,
    this.failure,
    this.cause,
  });

  final String? endpoint;
  final int? statusCode;
  final String? responseBody;
  final TaskRunFailure? failure;
  final Object? cause;

  @override
  String toString() =>
      'TaskRunnerDatasourceExecutionException(endpoint: $endpoint, statusCode: $statusCode, responseBody: $responseBody, failure: $failure, cause: $cause)';
}
