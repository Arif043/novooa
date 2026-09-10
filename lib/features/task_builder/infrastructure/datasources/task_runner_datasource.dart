abstract interface class TaskRunnerDatasource {
  Future<Map<String, Object?>> runTaskDefinition(Map<String, Object?> request);
}
