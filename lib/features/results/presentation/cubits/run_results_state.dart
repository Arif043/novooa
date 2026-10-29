import '../../../activity/domain/entities/task_run.dart';

sealed class RunResultsState {
  const RunResultsState();
}

final class RunResultsLoading extends RunResultsState {
  const RunResultsLoading();
}

final class RunResultsFailure extends RunResultsState {
  const RunResultsFailure();
}

final class RunResultsReady extends RunResultsState {
  const RunResultsReady({
    required this.runs,
    this.statusFilter,
    this.selectedRunId,
  });

  /// Neueste zuerst.
  final List<TaskRun> runs;

  /// `null` zeigt alle Läufe.
  final TaskRunStatus? statusFilter;

  /// Der Lauf, der in der Detailspalte steht (breite Ansicht).
  final String? selectedRunId;

  /// Der gewählte Lauf, sonst der neueste sichtbare.
  TaskRun? get selectedRun {
    final visible = visibleRuns;
    return visible.where((run) => run.id.value == selectedRunId).firstOrNull ??
        visible.firstOrNull;
  }

  List<TaskRun> get visibleRuns {
    final filter = statusFilter;
    if (filter == null) return runs;
    return runs.where((run) => run.status == filter).toList();
  }

  /// Nur Status, die vorkommen, sind als Filter sinnvoll.
  Set<TaskRunStatus> get presentStatuses =>
      runs.map((run) => run.status).toSet();
}
