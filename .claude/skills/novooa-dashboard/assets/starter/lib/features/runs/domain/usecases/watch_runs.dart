import '../entities/task_run.dart';
import '../repositories/run_repository.dart';

/// Läufe der angebotenen Aufgaben, höchstens [limit].
class WatchRuns {
  const WatchRuns(this._runs, {required this.isOffered, required this.limit});

  final RunRepository _runs;
  final bool Function(TaskId id) isOffered;
  final int limit;

  Stream<List<TaskRun>> call() => _runs.watchRuns().map(
    (runs) => runs.where((run) => isOffered(run.taskId)).take(limit).toList(),
  );
}
