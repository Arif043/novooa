import '../entities/application_log.dart';
import '../repositories/application_log_repository.dart';

class WatchApplicationLogs {
  const WatchApplicationLogs(this._repository);

  final ApplicationLogRepository _repository;

  Stream<List<ApplicationLog>> call() => _repository.watchRecent();
}
