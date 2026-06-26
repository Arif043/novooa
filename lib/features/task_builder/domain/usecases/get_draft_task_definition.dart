import '../entities/task_definition.dart';
import '../repositories/task_definition_repository.dart';

/// Use Case: aktuellen Entwurf aus dem Repository laden.
class GetDraftTaskDefinition {
  const GetDraftTaskDefinition(this.repository);

  final TaskDefinitionRepository repository;

  Future<TaskDefinition> execute() {
    return repository.loadDraft();
  }
}
