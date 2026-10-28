import 'package:multiple_result/multiple_result.dart';

import '../../../activity/domain/entities/task_run.dart';
import '../entities/run_result.dart';
import '../entities/run_result_failure.dart';

abstract interface class RunResultRepository {
  /// Graph und alle Node-Aktivitäten eines Laufs.
  Future<Result<RunResult, RunResultFailure>> load(TaskRun run);
}
