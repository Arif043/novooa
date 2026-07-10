import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../task_builder/domain/entities/task.dart';
import '../../../task_builder/domain/repositories/task_repository.dart';
import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../../domain/usecases/create_task_trigger.dart';
import '../../domain/usecases/delete_task_trigger.dart';
import '../../domain/usecases/set_task_trigger_enabled.dart';
import '../../domain/usecases/watch_task_triggers.dart';
import 'schedule_state.dart';

class ScheduleCubit extends Cubit<ScheduleState> {
  ScheduleCubit({
    required WatchTaskTriggers watchTaskTriggers,
    required CreateTaskTrigger createTaskTrigger,
    required SetTaskTriggerEnabled setTaskTriggerEnabled,
    required DeleteTaskTrigger deleteTaskTrigger,
    required TaskRepository taskRepository,
  }) : this._(
         watchTaskTriggers,
         createTaskTrigger,
         setTaskTriggerEnabled,
         deleteTaskTrigger,
         taskRepository,
       );

  ScheduleCubit._(
    this._watchTaskTriggers,
    this._createTaskTrigger,
    this._setTaskTriggerEnabled,
    this._deleteTaskTrigger,
    this._taskRepository,
  ) : super(const ScheduleState());

  final WatchTaskTriggers _watchTaskTriggers;
  final CreateTaskTrigger _createTaskTrigger;
  final SetTaskTriggerEnabled _setTaskTriggerEnabled;
  final DeleteTaskTrigger _deleteTaskTrigger;
  final TaskRepository _taskRepository;
  StreamSubscription<List<TaskTrigger>>? _subscription;

  Future<void> load() async {
    emit(const ScheduleState());
    try {
      final tasks = await _taskRepository.loadTasks();
      _subscription?.cancel();
      _subscription = _watchTaskTriggers().listen(
        (triggers) => _emitReady(tasks, triggers),
        onError: (_) => _emitFailure(),
      );
    } catch (_) {
      _emitFailure();
    }
  }

  Future<void> createTrigger(Task task, ScheduleConfig schedule) async {
    await _createTaskTrigger(
      CreateTaskTriggerInput(
        taskId: task.id,
        taskTitle: task.title,
        schedule: schedule,
      ),
    );
  }

  Future<void> setEnabled(TaskTrigger trigger, bool enabled) {
    return _setTaskTriggerEnabled(trigger.id, enabled);
  }

  Future<void> deleteTrigger(TaskTrigger trigger) {
    return _deleteTaskTrigger(trigger.id);
  }

  void _emitReady(List<Task> tasks, List<TaskTrigger> triggers) {
    if (isClosed) return;
    emit(
      ScheduleState(
        status: ScheduleStatus.ready,
        tasks: tasks,
        triggers: triggers,
      ),
    );
  }

  void _emitFailure() {
    if (isClosed) return;
    emit(
      const ScheduleState(
        status: ScheduleStatus.failure,
        message: 'Zeitpläne konnten nicht geladen werden.',
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
