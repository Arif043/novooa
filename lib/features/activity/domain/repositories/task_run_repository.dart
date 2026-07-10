import '../entities/task_run.dart';

abstract interface class TaskRunRepository {
  Future<List<TaskRun>> listRecent();
}
