import 'package:multiple_result/multiple_result.dart';

import '../../../activity/domain/entities/task_run.dart';
import '../entities/run_result.dart';
import '../entities/run_result_failure.dart';
import '../repositories/run_result_repository.dart';

class LoadRunResult {
  const LoadRunResult(this._repository);

  final RunResultRepository _repository;

  Future<Result<RunResult, RunResultFailure>> call(TaskRun run) =>
      _repository.load(run);
}
