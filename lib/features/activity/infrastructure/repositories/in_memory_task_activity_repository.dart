import '../../domain/entities/task_activity.dart';
import '../../domain/repositories/task_activity_repository.dart';

class InMemoryTaskActivityRepository implements TaskActivityRepository {
  final List<TaskActivity> _activities = [];

  @override
  Future<void> add(TaskActivity activity) async {
    _activities.add(activity);
  }

  @override
  Future<List<TaskActivity>> listRecent() async {
    return List.unmodifiable(_activities.reversed);
  }
}
