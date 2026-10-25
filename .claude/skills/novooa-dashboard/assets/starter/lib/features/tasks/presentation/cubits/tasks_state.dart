import '../../domain/entities/dashboard_task.dart';

sealed class TasksState {
  const TasksState();
}

final class TasksLoading extends TasksState {
  const TasksLoading();
}

final class TasksFailure extends TasksState {
  const TasksFailure();
}

/// Kann leer sein; die Seite zeigt dann einen eigenen Leerzustand.
final class TasksLoaded extends TasksState {
  const TasksLoaded(this.tasks);

  final List<DashboardTask> tasks;
}
