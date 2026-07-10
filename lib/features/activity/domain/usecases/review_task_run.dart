import '../entities/task_run.dart';
import '../repositories/task_run_repository.dart';

class ReviewTaskRun {
  const ReviewTaskRun(this._repository);

  final TaskRunRepository _repository;

  Future<void> call({
    required TaskRun run,
    required TaskRunReviewDecision decision,
    required String output,
  }) {
    return _repository.review(run: run, decision: decision, output: output);
  }
}
