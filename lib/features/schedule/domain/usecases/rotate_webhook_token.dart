import '../repositories/task_trigger_repository.dart';

class RotateWebhookToken {
  const RotateWebhookToken(this._repository);

  final TaskTriggerRepository _repository;

  Future<void> call(String triggerId) {
    return _repository.rotateWebhookToken(triggerId);
  }
}
