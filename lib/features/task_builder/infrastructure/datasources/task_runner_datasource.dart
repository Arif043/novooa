abstract interface class TaskClient {
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request);
}

class TaskClientConnectionException implements Exception {
  const TaskClientConnectionException({this.endpoint, this.cause});

  final String? endpoint;
  final Object? cause;

  @override
  String toString() {
    return 'TaskClientConnectionException('
        'endpoint: $endpoint, '
        'cause: $cause'
        ')';
  }
}

class TaskClientTimeoutException implements Exception {
  const TaskClientTimeoutException({
    required this.endpoint,
    required this.timeout,
    this.cause,
  });

  final String endpoint;
  final Duration timeout;
  final Object? cause;

  @override
  String toString() {
    return 'TaskClientTimeoutException('
        'endpoint: $endpoint, '
        'timeout: $timeout, '
        'cause: $cause'
        ')';
  }
}

class TaskClientExecutionException implements Exception {
  const TaskClientExecutionException({
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
    return 'TaskClientExecutionException('
        'endpoint: $endpoint, '
        'statusCode: $statusCode, '
        'responseBody: $responseBody, '
        'cause: $cause'
        ')';
  }
}
