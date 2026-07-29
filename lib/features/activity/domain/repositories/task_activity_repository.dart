import '../entities/task_activity.dart';

abstract interface class TaskActivityRepository {
  Future<void> add(TaskActivity activity);

  Stream<List<TaskActivity>> watchRecent();
}
