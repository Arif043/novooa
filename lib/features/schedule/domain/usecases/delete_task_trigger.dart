import '../repositories/task_trigger_repository.dart';

class DeleteTaskTrigger {
  const DeleteTaskTrigger(this._repository);

  final TaskTriggerRepository _repository;

  Future<void> call(String triggerId) {
    return _repository.deleteTrigger(triggerId);
  }
}
