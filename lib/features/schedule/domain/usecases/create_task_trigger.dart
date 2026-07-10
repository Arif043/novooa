import '../entities/create_task_trigger_input.dart';
import '../repositories/task_trigger_repository.dart';

class CreateTaskTrigger {
  const CreateTaskTrigger(this._repository);

  final TaskTriggerRepository _repository;

  Future<void> call(CreateTaskTriggerInput input) {
    return _repository.createTrigger(input);
  }
}
