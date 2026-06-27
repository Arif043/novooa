import '../entities/task_activity.dart';
import '../repositories/task_activity_repository.dart';

class ListTaskActivities {
  const ListTaskActivities(this._repository);

  final TaskActivityRepository _repository;

  Future<List<TaskActivity>> call() {
    return _repository.listRecent();
  }
}
