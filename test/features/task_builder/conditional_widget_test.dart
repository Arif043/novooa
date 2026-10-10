import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_widget.dart';

void main() {
  testWidgets('zeigt einen Hinweis statt der Wenn-Eingabe, wenn der direkte '
      'Vorgänger ein Entscheidungs-Prompt ist', (tester) async {
    final node = _conditionalNode();
    final task = _taskFor(
      node,
      precedingPrompt: const WorkflowNode(
        id: NodeId('prompt.1'),
        title: 'Prompt',
        description: '',
        outputs: [WorkflowOutput.primary('entscheidung')],
        config: PromptNodeConfig(
          instruction: '',
          outputType: PromptOutputType.decision,
          choices: ['Ja'],
        ),
      ),
    );
    await tester.pumpWidget(await _app(task, node));

    expect(find.text('Wenn'), findsNothing);
    expect(
      find.text(
        'Die Verzweigungen werden aus dem vorherigen Prompt-Baustein '
        'ermittelt.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('zeigt den Baukasten-Editor mit leerem Zustand, wenn kein '
      'Entscheidungs-Prompt direkt vorausgeht und noch keine Bedingung '
      'existiert', (tester) async {
    final node = _branchFreeConditionalNode();
    await tester.pumpWidget(await _app(_taskFor(node), node));

    expect(find.text('Pfade festlegen'), findsOneWidget);
    expect(
      find.text(
        'Noch keine Bedingung — ohne Bedingung läuft dieser Baustein '
        'direkt weiter.',
      ),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Bedingung hinzufügen'),
      findsOneWidget,
    );
  });

  testWidgets('fügt über "Bedingung hinzufügen" einen bedingten Branch plus '
      'automatischen Sonst-Branch hinzu', (tester) async {
    final node = _branchFreeConditionalNode();
    final cubit = TaskBuilderCubit(
      repository: _FakeTaskRepository(_taskFor(node)),
    );
    await cubit.load(_taskFor(node));
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
              builder: (context, state) {
                final currentNode =
                    (state as TaskBuilderLoaded).editingTask.nodes.single;
                return SingleChildScrollView(
                  child: ConditionalWidget(node: currentNode),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Bedingung hinzufügen'),
    );
    await tester.pump();

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.single.config as ConditionalNodeConfig;
    expect(config.branches, hasLength(2));
    expect(config.branches[0].condition, isNotNull);
    expect(config.branches[1].label, 'Sonst');
    expect(config.branches[1].condition, isNull);
    await cubit.close();
  });
}

Future<Widget> _app(Task task, WorkflowNode node) async {
  final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
  await cubit.load(task);
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(body: ConditionalWidget(node: node)),
    ),
  );
}

Task _taskFor(WorkflowNode conditionalNode, {WorkflowNode? precedingPrompt}) {
  final nodes = [?precedingPrompt, conditionalNode];
  final edges = [
    if (precedingPrompt != null)
      WorkflowEdge(from: precedingPrompt.id, to: conditionalNode.id),
  ];
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalNode.id,
    graph: WorkflowGraph(nodes: nodes, edges: edges),
  );
}

WorkflowNode _conditionalNode() {
  return const WorkflowNode(
    id: NodeId('node.1'),
    title: 'Verzweigung',
    description: 'Beschreibung',
    config: ConditionalNodeConfig(
      branches: [
        ConditionalBranch(
          id: 'branch.yes',
          label: 'Ja',
          graph: WorkflowGraph(nodes: [], edges: []),
        ),
      ],
    ),
  );
}

WorkflowNode _branchFreeConditionalNode() {
  return const WorkflowNode(
    id: NodeId('node.1'),
    title: 'Verzweigung',
    description: 'Beschreibung',
    config: ConditionalNodeConfig(branches: []),
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
