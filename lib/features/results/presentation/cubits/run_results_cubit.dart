import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../activity/domain/entities/task_run.dart';
import '../../../activity/domain/usecases/watch_task_runs.dart';
import 'run_results_state.dart';

class RunResultsCubit extends Cubit<RunResultsState> {
  RunResultsCubit(this._watchTaskRuns) : super(const RunResultsLoading());

  final WatchTaskRuns _watchTaskRuns;
  StreamSubscription<List<TaskRun>>? _subscription;
  TaskRunStatus? _statusFilter;
  String? _selectedRunId;

  void load() {
    unawaited(_subscription?.cancel());
    emit(const RunResultsLoading());
    _subscription = _watchTaskRuns().listen(
      (runs) => _emitReady(runs),
      onError: (_) {
        if (!isClosed) emit(const RunResultsFailure());
      },
    );
  }

  /// `null` zeigt wieder alle Läufe.
  void filterByStatus(TaskRunStatus? status) {
    _statusFilter = status;
    final current = state;
    if (current is RunResultsReady) _emitReady(current.runs);
  }

  void select(TaskRun run) {
    _selectedRunId = run.id.value;
    final current = state;
    if (current is RunResultsReady) _emitReady(current.runs);
  }

  void _emitReady(List<TaskRun> runs) {
    if (isClosed) return;
    emit(
      RunResultsReady(
        runs: runs,
        statusFilter: _statusFilter,
        selectedRunId: _selectedRunId,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
