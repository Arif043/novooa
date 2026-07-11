import 'schedule_config.dart';
import 'event_trigger_config.dart';

enum TriggerType { schedule, event }

enum TriggerRunPolicy { skipIfRunning, startParallel }

class TaskTrigger {
  const TaskTrigger({
    required this.id,
    required this.teamId,
    required this.taskId,
    required this.taskTitle,
    required this.type,
    required this.enabled,
    required this.policy,
    this.schedule,
    this.event,
    this.nextRunAt,
    this.lastRunAt,
    this.lastRunId,
  });

  final String id;
  final String teamId;
  final String taskId;
  final String taskTitle;
  final TriggerType type;
  final bool enabled;
  final ScheduleConfig? schedule;
  final EventTriggerConfig? event;
  final TriggerRunPolicy policy;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String? lastRunId;

  TaskTrigger copyWith({
    bool? enabled,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? lastRunId,
  }) {
    return TaskTrigger(
      id: id,
      teamId: teamId,
      taskId: taskId,
      taskTitle: taskTitle,
      type: type,
      enabled: enabled ?? this.enabled,
      schedule: schedule,
      event: event,
      policy: policy,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      lastRunId: lastRunId ?? this.lastRunId,
    );
  }
}
