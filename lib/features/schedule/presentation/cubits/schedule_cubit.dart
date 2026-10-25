import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../../task_builder/domain/entities/task.dart';
import '../../../task_builder/domain/repositories/task_repository.dart';
import '../../domain/entities/create_task_trigger_input.dart';
import '../../domain/entities/event_trigger_config.dart';
import '../../domain/entities/schedule_config.dart';
import '../../domain/entities/task_trigger.dart';
import '../../domain/entities/trigger_cycle_analysis.dart';
import '../../domain/usecases/analyze_task_trigger.dart';
import '../../domain/usecases/create_task_trigger.dart';
import '../../domain/usecases/delete_task_trigger.dart';
import '../../domain/usecases/rotate_webhook_token.dart';
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
    required AnalyzeTaskTrigger analyzeTaskTrigger,
    required RotateWebhookToken rotateWebhookToken,
  }) : this._(
         watchTaskTriggers,
         createTaskTrigger,
         setTaskTriggerEnabled,
         deleteTaskTrigger,
         taskRepository,
         analyzeTaskTrigger,
         rotateWebhookToken,
       );

  ScheduleCubit._(
    this._watchTaskTriggers,
    this._createTaskTrigger,
    this._setTaskTriggerEnabled,
    this._deleteTaskTrigger,
    this._taskRepository,
    this._analyzeTaskTrigger,
    this._rotateWebhookToken,
  ) : super(const ScheduleState());

  final WatchTaskTriggers _watchTaskTriggers;
  final CreateTaskTrigger _createTaskTrigger;
  final SetTaskTriggerEnabled _setTaskTriggerEnabled;
  final DeleteTaskTrigger _deleteTaskTrigger;
  final TaskRepository _taskRepository;
  final AnalyzeTaskTrigger _analyzeTaskTrigger;
  final RotateWebhookToken _rotateWebhookToken;
  StreamSubscription<List<TaskTrigger>>? _triggersSubscription;
  StreamSubscription<List<Task>>? _tasksSubscription;
  List<Task> _tasks = const [];
  List<TaskTrigger> _triggers = const [];

  Future<void> load() async {
    emit(const ScheduleState());
    _triggersSubscription?.cancel();
    _tasksSubscription?.cancel();
    _triggersSubscription = _watchTaskTriggers().listen(
      _onTriggers,
      onError: (_) => _emitFailure(),
    );
    _tasksSubscription = _taskRepository.watchTasks().listen(
      _onTasks,
      onError: (_) => _emitFailure(),
    );
  }

  Future<void> createTrigger(Task task, ScheduleConfig schedule) async {
    await _createTaskTrigger(
      CreateTaskTriggerInput(
        taskId: task.id,
        taskTitle: task.title,
        type: TriggerType.schedule,
        schedule: schedule,
      ),
    );
  }

  /// Prüft vorab auf Schleifen.
  Future<TriggerCycleAnalysis> analyzeEventTrigger(
    Task task,
    EventTriggerConfig event,
  ) {
    return _analyzeTaskTrigger(
      CreateTaskTriggerInput(
        taskId: task.id,
        taskTitle: task.title,
        type: TriggerType.event,
        event: event,
      ),
    );
  }

  Future<void> createEventTrigger(Task task, EventTriggerConfig event) async {
    await _createTaskTrigger(
      CreateTaskTriggerInput(
        taskId: task.id,
        taskTitle: task.title,
        type: TriggerType.event,
        event: event,
      ),
    );
  }

  Future<void> setEnabled(TaskTrigger trigger, bool enabled) {
    return _setTaskTriggerEnabled(trigger.id, enabled);
  }

  Future<void> deleteTrigger(TaskTrigger trigger) {
    return _deleteTaskTrigger(trigger.id);
  }

  /// Vergibt dem Webhook-Auslöser eine neue Adresse; die bisherige wird
  /// ungültig.
  Future<void> rotateWebhookToken(TaskTrigger trigger) {
    return _rotateWebhookToken(trigger.id);
  }

  void _onTasks(List<Task> tasks) {
    _tasks = tasks;
    _emitReady();
  }

  void _onTriggers(List<TaskTrigger> triggers) {
    _triggers = triggers;
    _emitReady();
  }

  void _emitReady() {
    if (isClosed) return;
    emit(
      ScheduleState(
        status: ScheduleStatus.ready,
        tasks: _tasks,
        triggers: _triggers,
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
  Future<void> close() async {
    await _triggersSubscription?.cancel();
    await _tasksSubscription?.cancel();
    return super.close();
  }
}
