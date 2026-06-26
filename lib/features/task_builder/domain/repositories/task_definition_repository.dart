import '../entities/task_definition.dart';

/// Vertrag für die Persistenz von [TaskDefinition]-Entwürfen.
///
/// Wird in der Domain-Schicht deklariert und in `infrastructure/` durch
/// konkrete Implementierungen (aktuell `InMemory`, später Firestore)
/// erfüllt. Die Cubit-Schicht hängt ausschließlich von diesem Interface.
abstract interface class TaskDefinitionRepository {
  Future<TaskDefinition> loadDraft();
  Future<void> saveDraft(TaskDefinition taskDefinition);
}
