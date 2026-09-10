import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';

void main() {
  testWidgets('tauscht Nodes und beendet den Drag beim Loslassen', (
    tester,
  ) async {
    final repository = _TestTaskRepository();
    final cubit = TaskBuilderCubit(repository: repository);
    await cubit.load(_task);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(body: NodeGraph(nodes: _nodes)),
        ),
      ),
    );

    final gesture = await tester.startGesture(_center(tester, 'node.1'));
    await gesture.moveTo(_center(tester, 'node.2'));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.map((node) => node.id.value), [
      'node.2',
      'node.1',
    ]);
    expect(_isFocusable(tester, 'node.1'), isTrue);
    await cubit.close();
  });
}

Offset _center(WidgetTester tester, String nodeId) {
  return tester.getCenter(find.byKey(ValueKey('node-drag-strip-$nodeId')));
}

bool _isFocusable(WidgetTester tester, String nodeId) {
  return tester
      .widget<FocusScope>(find.byKey(ValueKey('node-focus-$nodeId')))
      .descendantsAreFocusable;
}

class _TestTaskRepository implements TaskRepository {
  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => throw UnimplementedError();

  @override
  Stream<List<Task>> watchTasks() => Stream.value(const [_task]);

  @override
  Future<void> saveTask(Task task) async {}
}

const _task = Task(
  id: 'task.drag',
  title: 'Drag',
  objective: '',
  selectedNodeId: NodeId('node.1'),
  graph: WorkflowGraph(nodes: _nodes, edges: []),
);

const _nodes = [
  WorkflowNode(
    id: NodeId('node.1'),
    title: 'Eins',
    description: '',
    referenceName: 'eins',
    config: StringInputNodeConfig(value: ''),
  ),
  WorkflowNode(
    id: NodeId('node.2'),
    title: 'Zwei',
    description: '',
    referenceName: 'zwei',
    config: StringInputNodeConfig(value: ''),
  ),
];
