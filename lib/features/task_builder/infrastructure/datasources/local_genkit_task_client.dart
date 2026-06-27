abstract interface class LocalGenkitTaskClient {
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request);
}

class LocalGenkitConnectionException implements Exception {
  const LocalGenkitConnectionException();
}

class LocalGenkitExecutionException implements Exception {
  const LocalGenkitExecutionException();
}
