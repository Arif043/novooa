import '../entities/task_definition.dart';
import '../repositories/task_definition_repository.dart';

/// Use Case: Entwurf im Repository ablegen.
///
/// Der Cubit ruft diesen Use Case nach jeder Mutation auf, um die
/// Persistenz-Invariante aus `docs/features/aufgabe.md` zu erfüllen.
class SaveDraftTaskDefinition {
  const SaveDraftTaskDefinition(this.repository);

  final TaskDefinitionRepository repository;

  Future<void> execute(TaskDefinition taskDefinition) {
    return repository.saveDraft(taskDefinition);
  }
}