import '../entities/task_definition.dart';

abstract interface class TaskDefinitionRepository {
  Future<TaskDefinition> loadDraft();
  Future<void> saveDraft(TaskDefinition taskDefinition);
}
