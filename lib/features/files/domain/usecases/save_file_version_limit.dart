import '../repositories/file_settings_repository.dart';

class SaveFileVersionLimit {
  const SaveFileVersionLimit(this._repository);

  static const minimum = 1;
  static const maximum = 1000;

  final FileSettingsRepository _repository;

  Future<void> call(int limit) {
    if (limit < minimum || limit > maximum) {
      throw ArgumentError.value(limit, 'limit', 'Außerhalb des Bereichs.');
    }
    return _repository.saveVersionLimit(limit);
  }
}
