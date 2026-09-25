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

// Deckt `TaskBuilderBranchMutations.updateConditionalBranchLabel` ab — den
// neuen Mutations-Pfad für das Doppelklick-Umbenennen von
// Bedingungs-Branch-Labels ("Ja"/"Nein") direkt auf der Leinwand.
const conditionalId = NodeId('conditional.1');

void main() {
  test(
    'benennt genau den angesprochenen Zweig um und lässt andere Zweige '
    'sowie valueTemplate unverändert',
    () async {
      final cubit = await _cubitFor(_taskWithConditional());

      await cubit.updateConditionalBranchLabel(
        conditionalNodeId: conditionalId,
        branchId: 'branch.1',
        label: 'Vielleicht',
      );

      final config = _conditionalConfigOf(cubit);
      expect(config.branches[0].label, 'Vielleicht');
      expect(config.branches[1].label, 'Nein');
      expect(config.valueTemplate, '{{entscheidung}}');
      await cubit.close();
    },
  );

  test('entfernt umschließende Leerzeichen aus dem neuen Label', () async {
    final cubit = await _cubitFor(_taskWithConditional());

    await cubit.updateConditionalBranchLabel(
      conditionalNodeId: conditionalId,
      branchId: 'branch.2',
      label: '  Doch nicht  ',
    );

    final config = _conditionalConfigOf(cubit);
    expect(config.branches[1].label, 'Doch nicht');
    await cubit.close();
  });

  test('ignoriert ein leeres oder reines Leerzeichen-Label', () async {
    final cubit = await _cubitFor(_taskWithConditional());

    await cubit.updateConditionalBranchLabel(
      conditionalNodeId: conditionalId,
      branchId: 'branch.1',
      label: '   ',
    );

    final config = _conditionalConfigOf(cubit);
    expect(config.branches[0].label, 'Ja');
    await cubit.close();
  });

  test('lässt den Graphen unverändert, wenn die branchId nicht existiert', () async {
    final cubit = await _cubitFor(_taskWithConditional());

    await cubit.updateConditionalBranchLabel(
      conditionalNodeId: conditionalId,
      branchId: 'branch.unbekannt',
      label: 'Egal',
    );

    final config = _conditionalConfigOf(cubit);
    expect(config.branches[0].label, 'Ja');
    expect(config.branches[1].label, 'Nein');
    await cubit.close();
  });

  test(
    'synchronisiert die Antwort (Choice) des vorgeschalteten '
    'Entscheidungs-Prompts, wenn ein Branch-Label direkt auf der Leinwand '
    'umbenannt wird — sonst generiert der Prompt weiterhin die alte, nicht '
    'mehr passende Option',
    () async {
      final cubit = await _cubitFor(_taskWithDecisionPromptAndConditional());

      await cubit.updateConditionalBranchLabel(
        conditionalNodeId: conditionalId,
        branchId: 'branch.1',
        label: 'Doch',
      );

      final state = cubit.state as TaskBuilderLoaded;
      final promptConfig =
          state.editingTask.nodes
                  .firstWhere((node) => node.id == const NodeId('prompt.1'))
                  .config
              as PromptNodeConfig;
      expect(promptConfig.choices, ['Doch', 'Nein']);
      final config = _conditionalConfigOf(cubit);
      expect(config.branches[0].label, 'Doch');
      expect(config.branches[1].label, 'Nein');
      expect(config.valueTemplate, '{{entscheidung}}');
      await cubit.close();
    },
  );

  test(
    'lässt einen Bedingungs-Baustein ohne Entscheidungs-Prompt-Vorgänger '
    'weiterhin direkt umbenennbar (kein Sync-Ziel vorhanden)',
    () async {
      final cubit = await _cubitFor(_taskWithTextPromptAndConditional());

      await cubit.updateConditionalBranchLabel(
        conditionalNodeId: conditionalId,
        branchId: 'branch.1',
        label: 'Doch',
      );

      final state = cubit.state as TaskBuilderLoaded;
      final promptConfig =
          state.editingTask.nodes
                  .firstWhere((node) => node.id == const NodeId('prompt.1'))
                  .config
              as PromptNodeConfig;
      // Kein Entscheidungs-Prompt (outputType text) — dessen Inhalt bleibt
      // unangetastet, die Branch wird stattdessen direkt umbenannt.
      expect(promptConfig.instruction, 'Alte Anweisung');
      final config = _conditionalConfigOf(cubit);
      expect(config.branches[0].label, 'Doch');
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

Task _taskWithConditional() {
  const conditionalId = NodeId('conditional.1');
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalId,
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: conditionalId,
          title: 'Bedingter Ablauf',
          description: '',
          config: ConditionalNodeConfig.fromChoices(
            const ['Ja', 'Nein'],
          ).copyWith(valueTemplate: '{{entscheidung}}'),
        ),
      ],
      edges: const [],
    ),
  );
}

Task _taskWithDecisionPromptAndConditional() {
  const promptId = NodeId('prompt.1');
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
