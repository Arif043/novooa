import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/repositories/task_definition_repository.dart';

class InMemoryTaskDefinitionRepository implements TaskDefinitionRepository {
  InMemoryTaskDefinitionRepository() : _draft = _seedDraft();

  TaskDefinition _draft;

  @override
  Future<TaskDefinition> loadDraft() async {
    return _draft;
  }

  @override
  Future<void> saveDraft(TaskDefinition taskDefinition) async {
    _draft = taskDefinition;
  }

  static TaskDefinition _seedDraft() {
    const inputId = NodeId('node.input');
    const conditionId = NodeId('node.condition');
    const refineId = NodeId('node.refine');

    return TaskDefinition(
      id: 'draft.task',
      title: 'Neue Aufgabe',
      objective:
          'Automatisierbare Arbeit als kontrollierten Genkit-Flow bauen.',
      selectedNodeId: conditionId,
      nodes: const [
        WorkflowNode(
          id: inputId,
          primitive: WorkflowPrimitive.prompt,
          title: 'Eingabe verstehen',
          description: 'Nutzerziel, Kontext und Erfolgskriterium erfassen.',
        ),
        WorkflowNode(
          id: conditionId,
          primitive: WorkflowPrimitive.conditionalFlow,
          title: 'Entscheidung treffen',
          description: 'Auf Basis strukturierter Bedingungen verzweigen.',
        ),
        WorkflowNode(
          id: refineId,
          primitive: WorkflowPrimitive.iterativeRefinement,
          title: 'Ergebnis verbessern',
          description: 'Antwort erzeugen, kritisieren und gezielt verbessern.',
        ),
      ],
      edges: const [
        WorkflowEdge(from: inputId, to: conditionId),
        WorkflowEdge(
          from: conditionId,
          to: refineId,
          conditionLabel: 'wenn KI-Arbeit nötig',
        ),
      ],
    );
  }
}
