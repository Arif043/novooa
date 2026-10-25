import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/task_run.dart';
import '../../domain/usecases/watch_runs.dart';

sealed class RunsState {
  const RunsState();
}

final class RunsLoading extends RunsState {
  const RunsLoading();
}

final class RunsFailure extends RunsState {
  const RunsFailure();
}

final class RunsLoaded extends RunsState {
  const RunsLoaded(this.runs);

  final List<TaskRun> runs;
}

class RunsCubit extends Cubit<RunsState> {
  RunsCubit(this._watchRuns) : super(const RunsLoading());

  final WatchRuns _watchRuns;
  StreamSubscription<void>? _subscription;

  void load() {
    unawaited(_subscription?.cancel());
    emit(const RunsLoading());
    _subscription = _watchRuns().listen(
      (runs) => emit(RunsLoaded(runs)),
      onError: (Object _) => emit(const RunsFailure()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
