import 'package:multiple_result/multiple_result.dart';

import '../entities/task_run.dart';

abstract interface class RunRepository {
  /// Neueste Läufe zuerst; meldet sich bei jeder Änderung neu.
  Stream<List<TaskRun>> watchRuns();

  /// Antwortet auf einen wartenden Lauf. [formValues] nur bei Formularen.
  Future<Result<RunId, RunReviewFailure>> review(
    RunId id,
    RunReviewDecision decision, {
    Map<String, Object> formValues,
  });
}
