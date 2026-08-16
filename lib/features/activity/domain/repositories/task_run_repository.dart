import '../entities/task_run.dart';

abstract interface class TaskRunRepository {
  Stream<List<TaskRun>> watchRecent();

  Future<void> review({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
    Map<String, Object?> formValues = const {},
  });
}
