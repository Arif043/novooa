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
import 'package:syscat2/features/task_builder/presentation/widgets/compact_node_card.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas.dart';

// Ersetzt den alten `node_drag_test.dart`-Test (der auf der inzwischen
// entfernten `NodeGraph` — altes UI-Panel — basierte). Deckt denselben
// Ablauf über den tatsächlich verwendeten Drag-Mechanismus der
// Haupt-Leinwand ab: `BausteinSwapHandle` und `DragTarget<NodeId>` in
// `compact_workflow_node.dart`.
void main() {
  testWidgets(
    'tauscht zwei Bausteine, wenn einer auf den anderen gezogen wird',
    (tester) async {
      final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(_task));
      await cubit.load(_task);
      await tester.pumpWidget(_app(cubit));

      final source = tester.getCenter(
        find.byKey(const ValueKey('compact-node-drag-node.1')),
      );
      final target = tester.getCenter(
        find.byKey(const ValueKey('compact-node-node.2')),
      );
      final sourceCard = tester.getRect(_sourceCard('node.1'));
      final gesture = await tester.startGesture(source);
      await gesture.moveTo(target);
      await tester.pump();

      final feedbackCard = tester.getRect(_feedbackCard('node.1'));
      expect(feedbackCard.size, _closeToSize(sourceCard.size));
      expect(
        feedbackCard.topLeft,
        _closeToOffset(sourceCard.topLeft + (target - source)),
      );
      await gesture.up();
      await tester.pumpAndSettle();

      final state = cubit.state as TaskBuilderLoaded;
      expect(state.editingTask.nodes.map((node) => node.id.value), [
        'node.2',
        'node.1',
      ]);
      await cubit.close();
    },
  );
}

Finder _sourceCard(String nodeId) => find.ancestor(
  of: find.byKey(ValueKey('compact-node-drag-$nodeId')),
  matching: find.byType(CompactNodeCard),
);

Finder _feedbackCard(String nodeId) => find.descendant(
  of: find.byKey(ValueKey('compact-node-drag-feedback-$nodeId')),
  matching: find.byType(CompactNodeCard),
);

Matcher _closeToSize(Size expected) => isA<Size>()
    .having((size) => size.width, 'width', closeTo(expected.width, .01))
    .having((size) => size.height, 'height', closeTo(expected.height, .01));

Matcher _closeToOffset(Offset expected) => isA<Offset>()
    .having((offset) => offset.dx, 'dx', closeTo(expected.dx, .01))
    .having((offset) => offset.dy, 'dy', closeTo(expected.dy, .01));

Widget _app(TaskBuilderCubit cubit) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: WorkflowCanvas(
          graph: _task.graph,
          selected: null,
          onSelect: (_) {},
          onChoose: (_) {},
          onDrop: (_, _) {},
        ),
      ),
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

const _task = Task(
  id: 'task.drag',
  title: 'Drag',
  objective: '',
  selectedNodeId: NodeId('node.1'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.1'),
        title: 'Eins',
        description: '',
        outputs: [WorkflowOutput.primary('eins')],
        config: StringInputNodeConfig(value: ''),
      ),
      WorkflowNode(
        id: NodeId('node.2'),
        title: 'Zwei',
        description: '',
        outputs: [WorkflowOutput.primary('zwei')],
        config: StringInputNodeConfig(value: ''),
      ),
    ],
    edges: [WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.2'))],
  ),
);
