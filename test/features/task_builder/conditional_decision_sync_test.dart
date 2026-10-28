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
import 'package:syscat2/features/task_builder/domain/services/decision_branch_coverage.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

// Ein Bedingter Ablauf direkt nach einem Entscheidungs-Prompt bekommt
// sichtbare Bedingungen (`{{Antwort}}` ist gleich `Ja`) — beim Anhängen
// einmalig, danach nur noch per „Fehlende Zweige ergänzen“. Änderungen an
// den Antworten überschreiben den Ablauf nie still.
void main() {
  test('eine bearbeitete Antwort ändert den Ablauf nicht', () async {
    final cubit = await _cubitFor(_taskWithDecisionPromptAndConditional());
    final before = _conditionalConfigOf(cubit);

    await cubit.updatePromptChoice(
      nodeId: const NodeId('prompt.1'),
      choiceIndex: 0,
      value: 'Doch',
    );

    expect(_conditionalConfigOf(cubit), before);
    await cubit.close();
  });

  test('eine umbenannte Antwort zieht Tastendruck für Tastendruck nach; ein '
      'Zweig mit veränderter Bedingung bleibt gelöst', () async {
    final cubit = await _cubitFor(_taskWithSelectedDecisionPrompt());
    await cubit.addConnectedNode(
      primitive: WorkflowPrimitive.conditionalFlow,
      afterId: const NodeId('prompt.1'),
    );
    final conditionalId = _conditionalIdOf(cubit);
    await cubit.updateBranchCondition(
      conditionalNodeId: conditionalId,
      branchId: _conditionalConfigOf(cubit).branches[1].id,
      condition: const ComparisonCondition(
        left: '{{entscheidung}}',
        operator: ComparisonOperator.contains,
        right: 'Nein',
      ),
    );

    for (final typed in ['J', '', 'Z', 'Zu']) {
      await cubit.updatePromptChoice(
        nodeId: const NodeId('prompt.1'),
        choiceIndex: 0,
        value: typed,
      );
    }
    await cubit.updatePromptChoice(
      nodeId: const NodeId('prompt.1'),
      choiceIndex: 1,
      value: 'Niemals',
    );

    final config = _conditionalConfigOf(cubit);
    expect(config.branches[0].label, 'Zu');
    expect(config.branches[0].condition, _equals('Zu'));
    expect(config.branches[1].label, 'Nein');
    expect(
      (config.branches[1].condition! as ComparisonCondition).right,
      'Nein',
    );
    await cubit.close();
  });

  test('„Fehlende Zweige ergänzen“ fügt nur fehlende Antworten vor „Sonst“ '
      'ein', () async {
    final cubit = await _cubitFor(_taskWithDecisionPromptAndSonst());

    await cubit.addMissingDecisionBranches(const NodeId('conditional.1'));

    final config = _conditionalConfigOf(cubit);
    expect(config.choices, ['Ja', 'Nein', 'Sonst']);
    expect(config.branches[1].condition, _equals('Nein'));
    expect(config.branches.last.condition, isNull);
    await cubit.close();
  });

  test('erzeugt sichtbare Bedingungen, wenn ein neuer '
      'Bedingter-Ablauf-Baustein direkt nach einem Entscheidungs-Prompt '
      'angelegt wird', () async {
    final cubit = await _cubitFor(_taskWithSelectedDecisionPrompt());

    await cubit.addNodeToMainGraph(WorkflowPrimitive.conditionalFlow);

    _expectDecisionBranches(_conditionalConfigOf(cubit));
    await cubit.close();
  });

  test('lässt einen Bedingter-Ablauf-Nachfolger unverändert, wenn der '
      'Vorgänger-Prompt kein Entscheidungs-Output ist', () async {
    final cubit = await _cubitFor(_taskWithTextPromptAndConditional());

    await cubit.updatePromptChoice(
      nodeId: const NodeId('prompt.1'),
      choiceIndex: 0,
      value: 'Sollte ignoriert werden',
    );

    final config = _conditionalConfigOf(cubit);
    expect(config.choices, ['Ja', 'Nein']);
    expect(config.valueTemplate, '');
    await cubit.close();
  });

  test('fügt einen neuen Bedingter-Ablauf-Baustein branchfrei ein, wenn der '
      'Vorgänger kein Entscheidungs-Prompt ist — kein automatisches '
      '"Ja"/"Nein"', () async {
    final cubit = await _cubitFor(_taskWithSelectedStringInput());

    await cubit.addNodeToMainGraph(WorkflowPrimitive.conditionalFlow);

    final config = _conditionalConfigOf(cubit);
    expect(config.branches, isEmpty);
    await cubit.close();
  });

  test('fügt den allerersten Baustein eines leeren Arbeitsplans branchfrei '
      'ein, wenn es ein Bedingter-Ablauf-Baustein ist', () async {
    final cubit = await _cubitFor(Task.empty());

    await cubit.addNodeToMainGraph(WorkflowPrimitive.conditionalFlow);

    final config = _conditionalConfigOf(cubit);
    expect(config.branches, isEmpty);
    await cubit.close();
  });

  test(
    'bleibt auch über `addConnectedNode` (Leinwand-Einfügepunkt) branchfrei, '
    'wenn der explizite Vorgänger kein Entscheidungs-Prompt ist',
    () async {
      final cubit = await _cubitFor(_taskWithSelectedStringInput());

      await cubit.addConnectedNode(
        primitive: WorkflowPrimitive.conditionalFlow,
        afterId: const NodeId('string.1'),
      );

      final config = _conditionalConfigOf(cubit);
      expect(config.branches, isEmpty);
      await cubit.close();
    },
  );

  test(
    'erzeugt sichtbare Bedingungen auch über `addConnectedNode`, wenn direkt nach '
    'einem Entscheidungs-Prompt eingefügt wird',
    () async {
      final cubit = await _cubitFor(_taskWithSelectedDecisionPrompt());

      await cubit.addConnectedNode(
        primitive: WorkflowPrimitive.conditionalFlow,
        afterId: const NodeId('prompt.1'),
      );

      _expectDecisionBranches(_conditionalConfigOf(cubit));
      await cubit.close();
    },
  );
}

ComparisonCondition _equals(String answer) => ComparisonCondition(
  left: '{{entscheidung}}',
  operator: ComparisonOperator.equals,
  right: answer,
);

void _expectDecisionBranches(ConditionalNodeConfig config) {
  expect(config.choices, ['Ja', 'Nein', 'Vielleicht']);
  expect(config.branches.map((branch) => branch.condition), [
    _equals('Ja'),
    _equals('Nein'),
    _equals('Vielleicht'),
  ]);
}

Task _taskWithDecisionPromptAndSonst() {
  final task = _taskWithDecisionPromptAndConditional();
  final graph = task.graph;
  return task.copyWith(
    graph: graph.copyWith(
      nodes: [
        graph.nodes.first,
        graph.nodes.last.copyWith(
          config: ConditionalNodeConfig(
            branches: [
              decisionBranchFor(
                id: 'branch.1',
                answer: 'Ja',
                valueName: 'entscheidung',
              ),
              const ConditionalBranch(
                id: 'branch.2',
                label: 'Sonst',
                graph: WorkflowGraph(nodes: [], edges: []),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<TaskBuilderCubit> _cubitFor(Task task) async {
  final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
  await cubit.load(task);
  return cubit;
}

NodeId _conditionalIdOf(TaskBuilderCubit cubit) {
  final state = cubit.state as TaskBuilderLoaded;
  return state.editingTask.nodes
      .firstWhere((node) => node.config is ConditionalNodeConfig)
      .id;
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
          outputs: [WorkflowOutput.primary('entscheidung')],
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
          outputs: [WorkflowOutput.primary('freitext')],
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
          outputs: [WorkflowOutput.primary('entscheidung')],
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

Task _taskWithSelectedStringInput() {
  const stringInputId = NodeId('string.1');
  return const Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: stringInputId,
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: stringInputId,
          title: 'Text',
          description: '',
          outputs: [WorkflowOutput.primary('text')],
          config: StringInputNodeConfig(value: 'Beispiel'),
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
