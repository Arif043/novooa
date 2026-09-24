import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

// Deckt `TaskBuilderGraphMutations._syncConditionalSuccessors` ab: ein
// `conditionalFlow`-Baustein direkt nach einem Entscheidungs-Prompt
// übernimmt dessen Choices und `valueTemplate` automatisch — Grundlage
// dafür, dass `ConditionalWidget` seine manuelle „Wenn"-Eingabe für diesen
// Fall ausblenden darf, ohne die Ausführung zu brechen.
void main() {
  test(
    'aktualisiert Branch-Labels und valueTemplate, wenn eine '
    'Entscheidungs-Choice bearbeitet wird',
    () async {
      final cubit = await _cubitFor(_taskWithDecisionPromptAndConditional());

      await cubit.updatePromptChoice(
        nodeId: const NodeId('prompt.1'),
        choiceIndex: 0,
        value: 'Doch',
      );

      final config = _conditionalConfigOf(cubit);
      expect(config.choices, ['Doch', 'Nein']);
      expect(config.valueTemplate, '{{entscheidung}}');
      await cubit.close();
    },
  );

  test(
    'übernimmt Choices und valueTemplate sofort, wenn ein neuer '
    'Bedingter-Ablauf-Baustein direkt nach einem Entscheidungs-Prompt '
    'angelegt wird',
    () async {
      final cubit = await _cubitFor(_taskWithSelectedDecisionPrompt());

      await cubit.addNodeToMainGraph(WorkflowPrimitive.conditional);

      final config = _conditionalConfigOf(cubit);
      expect(config.choices, ['Ja', 'Nein', 'Vielleicht']);
      expect(config.valueTemplate, '{{entscheidung}}');
      await cubit.close();
    },
  );

  test(
    'lässt einen Bedingter-Ablauf-Nachfolger unverändert, wenn der '
    'Vorgänger-Prompt kein Entscheidungs-Output ist',
    () async {
      final cubit = await _cubitFor(_taskWithTextPromptAndConditional());

      // `updatePromptChoice` löst intern immer `_syncConditionalSuccessors`
      // aus — hier wird geprüft, dass der Guard auf `outputType == decision`
      // greift, auch wenn diese Methode (UI-seitig eigentlich nur für
      // Entscheidungs-Prompts erreichbar) trotzdem aufgerufen wird.
      await cubit.updatePromptChoice(
        nodeId: const NodeId('prompt.1'),
        choiceIndex: 0,
        value: 'Sollte ignoriert werden',
      );

      final config = _conditionalConfigOf(cubit);
      expect(config.choices, ['Ja', 'Nein']);
      expect(config.valueTemplate, '');
      await cubit.close();
    },
  );
}

Future<TaskBuilderCubit> _cubitFor(Task task) async {
  final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
  await cubit.load(task);
  return cubit;
}

ConditionalNodeConfig _conditionalConfigOf(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  return state.editingTask.nodes
          .firstWhere((node) => node.config is ConditionalNodeConfig)
          .config
      as ConditionalNodeConfig;
}

Task _taskWithDecisionPromptAndConditional() {
  const promptId = NodeId('prompt.1');
  const conditionalId = NodeId('conditional.1');
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalId,
    graph: WorkflowGraph(
      nodes: [
        const WorkflowNode(
          id: promptId,
          title: 'Prompt',
          description: '',
          outputName: 'entscheidung',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.decision,
            choices: ['Ja', 'Nein'],
          ),
        ),
        WorkflowNode(
          id: conditionalId,
          title: 'Bedingter Ablauf',
          description: '',
          config: ConditionalNodeConfig.fromChoices(const ['Ja', 'Nein']),
        ),
      ],
      edges: const [WorkflowEdge(from: promptId, to: conditionalId)],
    ),
  );
}

Task _taskWithTextPromptAndConditional() {
  const promptId = NodeId('prompt.1');
  const conditionalId = NodeId('conditional.1');
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalId,
    graph: WorkflowGraph(
      nodes: [
        const WorkflowNode(
          id: promptId,
          title: 'Prompt',
          description: '',
          outputName: 'freitext',
          config: PromptNodeConfig(
            instruction: 'Alte Anweisung',
            outputType: PromptOutputType.text,
            choices: [],
          ),
        ),
        WorkflowNode(
          id: conditionalId,
          title: 'Bedingter Ablauf',
          description: '',
          config: ConditionalNodeConfig.fromChoices(const ['Ja', 'Nein']),
        ),
      ],
      edges: const [WorkflowEdge(from: promptId, to: conditionalId)],
    ),
  );
}

Task _taskWithSelectedDecisionPrompt() {
  const promptId = NodeId('prompt.1');
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: promptId,
    graph: const WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: promptId,
          title: 'Prompt',
          description: '',
          outputName: 'entscheidung',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.decision,
            choices: ['Ja', 'Nein', 'Vielleicht'],
          ),
        ),
      ],
      edges: [],
    ),
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(this.task);

  Task task;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([task]);

  @override
  Future<void> saveTask(Task value) async => task = value;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    return const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
  }
}
