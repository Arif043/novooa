import 'event_trigger_config.dart';
import 'schedule_config.dart';
import 'task_trigger.dart';

class CreateTaskTriggerInput {
  const CreateTaskTriggerInput({
    required this.taskId,
    required this.taskTitle,
    required this.type,
    this.schedule,
    this.event,
    this.enabled = true,
    this.policy = TriggerRunPolicy.skipIfRunning,
  });

  final String taskId;
  final String taskTitle;
  final TriggerType type;
  final ScheduleConfig? schedule;
  final EventTriggerConfig? event;
  final bool enabled;
  final TriggerRunPolicy policy;

  bool get isValid {
    return switch (type) {
      TriggerType.schedule => schedule?.isValid ?? false,
      TriggerType.event => event?.isValid ?? false,
    };
  }
}
