import 'package:multiple_result/multiple_result.dart';

import '../entities/task_run.dart';
import '../repositories/run_repository.dart';

class ReviewRun {
  const ReviewRun(this._runs);

  final RunRepository _runs;

  Future<Result<RunId, RunReviewFailure>> call(
    TaskRun run,
    RunReviewDecision decision, {
    Map<String, Object> formValues = const {},
  }) => _runs.review(run.id, decision, formValues: formValues);
}
