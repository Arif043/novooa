import '../../domain/entities/task_definition.dart';
import '../../domain/entities/prompt_node_config.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/repositories/task_definition_repository.dart';

/// In-Memory-Implementierung des [TaskDefinitionRepository].
///
/// Seedet einen dreiköpfigen Beispiel-Flow, damit der Builder sofort
/// etwas Sichtbares hat. Überlebt keinen App-Restart — der Migrationspfad
/// zu Firestore ist in `docs/architecture.md` § Persistenz dokumentiert.
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
    const modelId = NodeId('node.model');
    const approveId = NodeId('node.approve');

    return TaskDefinition(
      id: 'draft.task',
      title: 'Neue Aufgabe',
      objective:
          'Automatisierbare Arbeit als kontrollierten Genkit-Flow bauen.',
      selectedNodeId: inputId,
      nodes: const [
        WorkflowNode(
          id: inputId,
          primitive: WorkflowPrimitive.prompt,
          title: 'Eingabe verstehen',
          description: 'Nutzerziel, Kontext und Erfolgskriterium erfassen.',
          promptConfig: PromptNodeConfig(
            instruction:
                'Fasse das Nutzerziel, den Kontext und das Erfolgskriterium zusammen.',
            outputType: PromptOutputType.text,
            firstChoice: '',
            secondChoice: '',
          ),
        ),
        WorkflowNode(
          id: conditionId,
          primitive: WorkflowPrimitive.conditionalFlow,
          title: 'Entscheidung treffen',
          description:
              'Verzweigt den Ablauf anhand von vordefinierten Regeln oder Logik-Sets.',
          logicMode: LogicMode.schemaBasiert,
        ),
        WorkflowNode(
          id: refineId,
          primitive: WorkflowPrimitive.iterativeRefinement,
          title: 'Ergebnis verbessern',
          description: 'Antwort erzeugen, kritisieren und gezielt verbessern.',
        ),
        WorkflowNode(
          id: modelId,
          primitive: WorkflowPrimitive.prompt,
          title: 'Modellauftrag',
          description: 'Formt Eingaben in einen Modellauftrag um.',
          promptConfig: PromptNodeConfig(
            instruction: 'Erzeuge eine klare Antwort auf Basis des Kontexts.',
            outputType: PromptOutputType.text,
            firstChoice: '',
            secondChoice: '',
          ),
        ),
        WorkflowNode(
          id: approveId,
          primitive: WorkflowPrimitive.humanApproval,
          title: 'Freigabe einholen',
          description: 'Wartet auf menschliche Freigabe vor dem Versand.',
        ),
      ],
      edges: const [
        WorkflowEdge(from: inputId, to: conditionId),
        WorkflowEdge(
          from: conditionId,
          to: refineId,
          conditionLabel: 'Wenn "Fehler"',
        ),
        WorkflowEdge(
          from: conditionId,
          to: modelId,
          conditionLabel: 'Wenn "Erfolg"',
        ),
        WorkflowEdge(from: refineId, to: approveId),
        WorkflowEdge(from: modelId, to: approveId),
      ],
    );
  }
}
