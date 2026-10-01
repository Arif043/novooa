import '../repositories/file_settings_repository.dart';

class WatchFileVersionLimit {
  const WatchFileVersionLimit(this._repository);

  final FileSettingsRepository _repository;

  Stream<int> call() => _repository.watchVersionLimit();
}
