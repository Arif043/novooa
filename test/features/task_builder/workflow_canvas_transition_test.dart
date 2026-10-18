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
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas_frame.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas_layout.dart';

void main() {
  test('ein entfernter Zweig blendet an seinem Platz aus, Kanten mit ihm', () {
    final before = WorkflowCanvasLayout(_graph(withSecondBranch: true));
    final after = WorkflowCanvasLayout(_graph(withSecondBranch: false));

    final frame = CanvasFrame.between(before, after, .25);

    expect(frame.departing, contains('nein-baustein'));
    expect(frame.opacityOf('nein-baustein'), .75);
    expect(
      frame.rectangles['nein-baustein'],
      before.rectangles['nein-baustein'],
    );
    final departingLink = frame.links.firstWhere(
      (link) => link.to == 'nein-baustein',
    );
    expect(frame.linkOpacityOf(departingLink), .75);
    expect(frame.opacityOf('ja-baustein'), 1);
  });

  testWidgets(
    'der Baustein eines entfernten Zweigs verschwindet erst nach dem Ausblenden',
    (tester) async {
      final cubit = TaskBuilderCubit(repository: _FakeTaskRepository());
      await tester.pumpWidget(_app(cubit, _graph(withSecondBranch: true)));
      await tester.pumpWidget(_app(cubit, _graph(withSecondBranch: false)));
      await tester.pump(const Duration(milliseconds: 175));

      final removed = find.byKey(const ValueKey('canvas-entry-nein-baustein'));
      expect(removed, findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.descendant(of: removed, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, inExclusiveRange(0, 1));

      await tester.pumpAndSettle();
      expect(removed, findsNothing);
      await cubit.close();
    },
  );
}

WorkflowGraph _graph({required bool withSecondBranch}) => WorkflowGraph(
  nodes: [
    WorkflowNode(
      id: const NodeId('bedingung'),
      title: 'Bedingung',
      description: '',
      config: ConditionalNodeConfig(
        branches: [_branch('ja'), if (withSecondBranch) _branch('nein')],
      ),
    ),
  ],
  edges: const [],
);

ConditionalBranch _branch(String id) => ConditionalBranch(
  id: id,
  label: id,
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('$id-baustein'),
        title: id,
        description: '',
        config: const StringInputNodeConfig(value: ''),
      ),
    ],
    edges: const [],
  ),
);

Widget _app(TaskBuilderCubit cubit, WorkflowGraph graph) {
  return MaterialApp(
    home: BlocProvider.value(
      value: cubit,
      child: Scaffold(
        body: WorkflowCanvas(
          graph: graph,
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
  @override
  Stream<List<Task>> watchTasks() => const Stream.empty();

  @override
  Future<void> saveTask(Task value) async {}

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
