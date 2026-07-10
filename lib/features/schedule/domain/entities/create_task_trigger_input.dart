import 'schedule_config.dart';
import 'task_trigger.dart';

class CreateTaskTriggerInput {
  const CreateTaskTriggerInput({
    required this.taskId,
    required this.taskTitle,
    required this.schedule,
    this.enabled = true,
    this.policy = TriggerRunPolicy.skipIfRunning,
  });

  final String taskId;
  final String taskTitle;
  final ScheduleConfig schedule;
  final bool enabled;
  final TriggerRunPolicy policy;
}
