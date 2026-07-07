abstract interface class TaskRunnerDatasource {
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request);
}

class TaskRunnerDatasourceConnectionException implements Exception {
  const TaskRunnerDatasourceConnectionException({this.endpoint, this.cause});

  final String? endpoint;
  final Object? cause;

  @override
  String toString() {
    return 'TaskRunnerDatasourceConnectionException('
        'endpoint: $endpoint, '
        'cause: $cause'
        ')';
  }
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
  String toString() {
    return 'TaskRunnerDatasourceTimeoutException('
        'endpoint: $endpoint, '
        'timeout: $timeout, '
        'cause: $cause'
        ')';
  }
}

class TaskRunnerDatasourceExecutionException implements Exception {
  const TaskRunnerDatasourceExecutionException({
    this.endpoint,
    this.statusCode,
    this.responseBody,
    this.cause,
  });

  final String? endpoint;
  final int? statusCode;
  final String? responseBody;
  final Object? cause;

  @override
  String toString() {
    return 'TaskRunnerDatasourceExecutionException('
        'endpoint: $endpoint, '
        'statusCode: $statusCode, '
        'responseBody: $responseBody, '
        'cause: $cause'
        ')';
  }
}
