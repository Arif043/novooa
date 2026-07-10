import '../entities/task_run.dart';

abstract interface class TaskRunRepository {
  Future<List<TaskRun>> listRecent();

  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
  });
}
