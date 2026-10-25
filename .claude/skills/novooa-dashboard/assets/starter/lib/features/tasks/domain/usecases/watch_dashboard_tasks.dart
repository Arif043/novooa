import '../entities/dashboard_task.dart';
import '../repositories/task_catalog.dart';

/// Aufgaben, die dieses Dashboard anbietet, alphabetisch.
class WatchDashboardTasks {
  const WatchDashboardTasks(this._catalog, {required this.isOffered});

  final TaskCatalog _catalog;

  /// Welche Aufgaben der Kunde sieht (siehe `DashboardConfig`).
  final bool Function(TaskId id) isOffered;

  Stream<List<DashboardTask>> call() => _catalog.watchTasks().map(
    (tasks) =>
        tasks.where((task) => isOffered(task.id)).toList()
          ..sort((a, b) => a.title.compareTo(b.title)),
  );
}
