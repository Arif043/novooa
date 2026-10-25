import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_task.dart';
import '../../domain/usecases/start_task.dart';

sealed class TaskStartState {
  const TaskStartState();
}

final class TaskStartIdle extends TaskStartState {
  const TaskStartIdle();
}

final class TaskStarting extends TaskStartState {
  const TaskStarting(this.task);

  final DashboardTask task;
}

final class TaskStarted extends TaskStartState {
  const TaskStarted(this.task, this.runId);

  final DashboardTask task;
  final RunId runId;
}

final class TaskStartFailed extends TaskStartState {
  const TaskStartFailed(this.task, this.failure);

  final DashboardTask task;
  final TaskStartFailure failure;
}

/// Startet eine Aufgabe und meldet das Ergebnis einmal an die Seite.
class TaskStartCubit extends Cubit<TaskStartState> {
  TaskStartCubit(this._startTask) : super(const TaskStartIdle());

  final StartTask _startTask;

  Future<void> start(DashboardTask task, {String context = ''}) async {
    if (state is TaskStarting) return;
    emit(TaskStarting(task));
    final runIdOrFailure = await _startTask(task, context: context);
    emit(
      runIdOrFailure.when(
        (runId) => TaskStarted(task, runId),
        (failure) => TaskStartFailed(task, failure),
      ),
    );
  }
}
