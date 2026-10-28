import 'package:bloc/bloc.dart';

import '../../../activity/domain/entities/task_run.dart';
import '../../domain/usecases/load_run_result.dart';
import 'run_result_state.dart';

class RunResultCubit extends Cubit<RunResultState> {
  RunResultCubit(this._loadRunResult) : super(const RunResultLoading());

  final LoadRunResult _loadRunResult;
  TaskRun? _run;

  Future<void> load(TaskRun run) async {
    _run = run;
    emit(const RunResultLoading());
    final resultOrFailure = await _loadRunResult(run);
    if (isClosed) return;
    emit(
      resultOrFailure.when(
        (result) => RunResultReady(result: result),
        (_) => const RunResultError(),
      ),
    );
  }

  Future<void> retry() async {
    final run = _run;
    if (run != null) await load(run);
  }

  /// Wählt die Runde einer Schleife; außerhalb der vorhandenen Runden nichts.
  void selectRound(String loopNodeId, int round) {
    final ready = _ready;
    if (ready == null) return;
    final count = ready.result.roundCountOf(loopNodeId);
    if (round < 0 || round >= count) return;
    emit(ready.copyWith(rounds: {...ready.rounds, loopNodeId: round}));
  }

  void selectNode(String nodeId) {
    final ready = _ready;
    if (ready != null) emit(ready.copyWith(selectedNodeId: nodeId));
  }

  void clearSelection() {
    final ready = _ready;
    if (ready != null) emit(ready.copyWith(clearSelection: true));
  }

  RunResultReady? get _ready => switch (state) {
    final RunResultReady ready => ready,
    _ => null,
  };
}
