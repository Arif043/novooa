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
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas.dart';

// Deckt das eigentliche Interaktionsmuster ab, das der Nutzer verlangt hat:
// Doppelklick auf ein Leinwand-Label macht dessen Text direkt inline
// editierbar (kein Dialog), Enter übernimmt die Änderung fachlich korrekt
// über den passenden `TaskBuilderCubit`-Aufruf. Geprüft für die zwei vom
// Plan explizit geforderten Fälle: Ausgabename und Bedingungs-Branch.
void main() {
  setUp(() {
    // Große Flächen vermeiden, dass ein Label außerhalb des sichtbaren
    // Viewports der `InteractiveViewer`-Leinwand landet und damit für
    // `tester.tap` nicht treffbar wäre.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<TaskBuilderCubit> pumpCanvas(WidgetTester tester, Task task) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(task));
    await cubit.load(task);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
              builder: (context, state) => WorkflowCanvas(
                graph: (state as TaskBuilderLoaded).editingTask.graph,
                selected: null,
                onSelect: (_) {},
                onChoose: (_) {},
                onDrop: (_, _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> doubleTap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets(
    'Doppelklick auf den Ausgabenamen-Chip macht ihn editierbar und '
    'übernimmt den neuen Namen via updateNodeOutputName',
    (tester) async {
      final cubit = await pumpCanvas(tester, _taskWithOutputNameEdge());

      expect(find.text('ausgabe'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await doubleTap(tester, find.text('ausgabe'));

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'umbenannt');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final updated = (cubit.state as TaskBuilderLoaded).editingTask.nodes
          .firstWhere((node) => node.id == const NodeId('quelle'));
      expect(updated.outputName, 'umbenannt');
      expect(find.byType(TextField), findsNothing);
      expect(find.text('umbenannt'), findsOneWidget);
      await cubit.close();
    },
  );

  testWidgets(
    'Doppelklick auf ein Bedingungs-Branch-Label ("Ja") benennt genau '
    'diesen Zweig via updateConditionalBranchLabel um',
    (tester) async {
      final cubit = await pumpCanvas(tester, _taskWithConditional());

      expect(find.text('Ja'), findsOneWidget);

      await doubleTap(tester, find.text('Ja'));

      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Vielleicht');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final config =
          (cubit.state as TaskBuilderLoaded).editingTask.nodes
                  .firstWhere((node) => node.id == const NodeId('decision'))
                  .config
              as ConditionalNodeConfig;
      expect(config.branches[0].label, 'Vielleicht');
      expect(config.branches[1].label, 'Nein');
      await cubit.close();
    },
  );
}

Task _taskWithOutputNameEdge() {
  const source = WorkflowNode(
    id: NodeId('quelle'),
    title: '',
    description: '',
    outputName: 'ausgabe',
    config: StringInputNodeConfig(value: ''),
  );
  const successor = WorkflowNode(
    id: NodeId('next'),
    title: '',
    description: '',
    config: StringInputNodeConfig(value: ''),
  );
  return const Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: NodeId('quelle'),
    graph: WorkflowGraph(
      nodes: [source, successor],
      edges: [WorkflowEdge(from: NodeId('quelle'), to: NodeId('next'))],
    ),
  );
}

Task _taskWithConditional() {
  const decision = WorkflowNode(
    id: NodeId('decision'),
    title: '',
    description: '',
    config: ConditionalNodeConfig(
      branches: [
        ConditionalBranch(
          id: 'branch.1',
          label: 'Ja',
          graph: WorkflowGraph(nodes: [], edges: []),
        ),
        ConditionalBranch(
          id: 'branch.2',
          label: 'Nein',
          graph: WorkflowGraph(nodes: [], edges: []),
        ),
      ],
    ),
  );
  return const Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: NodeId('decision'),
    graph: WorkflowGraph(nodes: [decision], edges: []),
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
