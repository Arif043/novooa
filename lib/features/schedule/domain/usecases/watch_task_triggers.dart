import '../entities/task_trigger.dart';
import '../repositories/task_trigger_repository.dart';

class WatchTaskTriggers {
  const WatchTaskTriggers(this._repository);

  final TaskTriggerRepository _repository;

  Stream<List<TaskTrigger>> call() {
    return _repository.watchTriggers();
  }
}
