import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/watch_dashboard_tasks.dart';
import 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(this._watchTasks) : super(const TasksLoading());

  final WatchDashboardTasks _watchTasks;
  StreamSubscription<void>? _subscription;

  void load() {
    unawaited(_subscription?.cancel());
    emit(const TasksLoading());
    _subscription = _watchTasks().listen(
      (tasks) => emit(TasksLoaded(tasks)),
      onError: (Object _) => emit(const TasksFailure()),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
