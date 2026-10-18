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

const _condition = NodeId('bedingung');
const _inBranch = NodeId('im-zweig');
const _outside = NodeId('aussen');

void main() {
  test('swapNodes tauscht einen Baustein im Zweig mit einem außerhalb und '
      'speichert', () async {
    final repository = _FakeTaskRepository(_task());
    final cubit = TaskBuilderCubit(repository: repository);
    await cubit.load(repository.task);

    expect(cubit.canSwapNodes(_inBranch, _outside), isTrue);
    await cubit.swapNodes(_inBranch, _outside);

    final graph = (cubit.state as TaskBuilderLoaded).editingTask.graph;
    final branch =
        (graph.nodes.first.config as ConditionalNodeConfig).branches.single;
    expect(graph.nodes.last.id, _inBranch);
    expect(branch.graph.nodes.single.id, _outside);
    await cubit.close();
    expect(repository.task.graph, graph);
  });

  test(
    'eine Bedingung lässt sich nicht in ihren eigenen Zweig ziehen',
    () async {
      final repository = _FakeTaskRepository(_task());
      final cubit = TaskBuilderCubit(repository: repository);
      await cubit.load(repository.task);

      expect(cubit.canSwapNodes(_condition, _inBranch), isFalse);
      await cubit.swapNodes(_condition, _inBranch);

      expect(
        (cubit.state as TaskBuilderLoaded).editingTask.graph,
        _task().graph,
      );
      await cubit.close();
    },
  );
}

Task _task() => Task(
  id: 'task',
  title: 'Aufgabe',
  objective: '',
  selectedNodeId: _condition,
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: _condition,
        title: 'Bedingung',
        description: '',
        config: ConditionalNodeConfig(
          branches: [
            ConditionalBranch(
              id: 'ja',
              label: 'Ja',
              graph: WorkflowGraph(nodes: [_node(_inBranch)], edges: const []),
            ),
          ],
        ),
      ),
      _node(_outside),
    ],
    edges: const [],
  ),
);

WorkflowNode _node(NodeId id) => WorkflowNode(
  id: id,
  title: id.value,
  description: '',
  config: const StringInputNodeConfig(value: ''),
);

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
