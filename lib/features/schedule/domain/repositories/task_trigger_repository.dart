import '../entities/create_task_trigger_input.dart';
import '../entities/task_trigger.dart';

abstract interface class TaskTriggerRepository {
  Stream<List<TaskTrigger>> watchTriggers();

  Future<void> createTrigger(CreateTaskTriggerInput input);

  Future<void> setTriggerEnabled(String triggerId, bool enabled);

  Future<void> deleteTrigger(String triggerId);
}
