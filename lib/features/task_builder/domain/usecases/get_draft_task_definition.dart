import '../entities/task_definition.dart';
import '../repositories/task_definition_repository.dart';

class GetDraftTaskDefinition {
  const GetDraftTaskDefinition(this.repository);

  final TaskDefinitionRepository repository;

  Future<TaskDefinition> execute() {
    return repository.loadDraft();
  }
}
