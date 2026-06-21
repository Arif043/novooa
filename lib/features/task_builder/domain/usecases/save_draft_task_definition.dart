import '../entities/task_definition.dart';
import '../repositories/task_definition_repository.dart';

class SaveDraftTaskDefinition {
  const SaveDraftTaskDefinition(this.repository);

  final TaskDefinitionRepository repository;

  Future<void> execute(TaskDefinition taskDefinition) {
    return repository.saveDraft(taskDefinition);
  }
}
