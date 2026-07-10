import '../repositories/task_trigger_repository.dart';

class SetTaskTriggerEnabled {
  const SetTaskTriggerEnabled(this._repository);

  final TaskTriggerRepository _repository;

  Future<void> call(String triggerId, bool enabled) {
    return _repository.setTriggerEnabled(triggerId, enabled);
  }
}
