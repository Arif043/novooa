import '../entities/task_run.dart';
import '../repositories/task_run_repository.dart';

class ListTaskRuns {
  const ListTaskRuns(this._repository);

  final TaskRunRepository _repository;

  Future<List<TaskRun>> call() {
    return _repository.listRecent();
  }
}
