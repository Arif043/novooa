import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Future<List<Task>> loadTasks() async => [savedTask];

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }
}

void main() {
  test('addNodeToBranch fuegt einen Node in den Branch-Graph ein', () async {
    final repository = _InMemoryTaskRepository(_taskWithConditionalNode());
    final cubit = TaskBuilderCubit(repository: repository);

    await cubit.load(repository.savedTask);
    await cubit.addNodeToBranch(
      conditionalNodeId: const NodeId('node.1'),
      branchId: 'branch.yes',
      primitive: WorkflowPrimitive.prompt,
    );

    final state = cubit.state as TaskBuilderLoaded;
    final config =
        state.editingTask.nodes.first.config as ConditionalNodeConfig;
    final branch = config.branches.first;

    expect(branch.graph.nodes, hasLength(1));
    expect(branch.graph.nodes.first.config, isA<PromptNodeConfig>());
    expect(repository.savedTask, state.editingTask);

    await cubit.close();
  });
}

Task _taskWithConditionalNode() {
  return const Task(
    id: 'task.1',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
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
        ),
      ],
      edges: [],
    ),
  );
}
