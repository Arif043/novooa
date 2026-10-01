abstract interface class FileSettingsRepository {
  Stream<int> watchVersionLimit();

  Future<void> saveVersionLimit(int limit);
}
