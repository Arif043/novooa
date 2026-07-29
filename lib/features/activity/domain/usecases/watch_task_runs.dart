import '../entities/task_run.dart';
import '../repositories/task_run_repository.dart';

class WatchTaskRuns {
  const WatchTaskRuns(this._repository);

  final TaskRunRepository _repository;

  Stream<List<TaskRun>> call() => _repository.watchRecent();
}
