abstract interface class TaskClient {
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request);
}

class LocalGenkitConnectionException implements Exception {
  const LocalGenkitConnectionException({this.endpoint, this.cause});

  final String? endpoint;
  final Object? cause;

  @override
  String toString() {
    return 'LocalGenkitConnectionException(endpoint: $endpoint, cause: $cause)';
  }
}

class LocalGenkitTimeoutException implements Exception {
  const LocalGenkitTimeoutException({required this.endpoint, required this.timeout, this.cause});

  final String endpoint;
  final Duration timeout;
  final Object? cause;

  @override
  String toString() {
    return 'LocalGenkitTimeoutException('
        'endpoint: $endpoint, '
        'timeout: $timeout, '
        'cause: $cause'
        ')';
  }
}

class LocalGenkitExecutionException implements Exception {
  const LocalGenkitExecutionException({this.endpoint, this.statusCode, this.responseBody, this.cause});

  final String? endpoint;
  final int? statusCode;
  final String? responseBody;
  final Object? cause;

  @override
  String toString() {
    return 'LocalGenkitExecutionException('
        'endpoint: $endpoint, '
        'statusCode: $statusCode, '
        'responseBody: $responseBody, '
        'cause: $cause'
        ')';
  }
}
