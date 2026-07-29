import '../entities/task_activity.dart';
import '../repositories/task_activity_repository.dart';

class WatchTaskActivities {
  const WatchTaskActivities(this._repository);

  final TaskActivityRepository _repository;

  Stream<List<TaskActivity>> call() => _repository.watchRecent();
}
