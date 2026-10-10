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

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([savedTask]);

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }

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

Task _taskWith(WorkflowNode node) => Task(
  id: 'task.outputs',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: node.id,
  graph: WorkflowGraph(nodes: [node], edges: const []),
);

const _start = WorkflowNode(
  id: NodeId('node.start'),
  title: 'Start',
  description: '',
  outputs: [WorkflowOutput.primary('Eingabe')],
  config: StringInputNodeConfig(value: ''),
);

Future<TaskBuilderCubit> _loadedCubit(Task task) async {
  final cubit = TaskBuilderCubit(repository: _InMemoryTaskRepository(task));
  await cubit.load(task);
  return cubit;
}

List<WorkflowNode> _nodes(TaskBuilderCubit cubit) =>
    (cubit.state as TaskBuilderLoaded).editingTask.nodes;

Future<void> _switchType(
  TaskBuilderCubit cubit,
  NodeId nodeId,
  PromptOutputType type,
) => cubit.updatePromptOutputType(nodeId, type);

WorkflowNode _nodeById(TaskBuilderCubit cubit, NodeId id) =>
    _nodes(cubit).firstWhere((node) => node.id == id);

void main() {
  test('Entscheidung heißt immer „Antwort“, auch nach eigenem Namen; '
      'zurück auf Freitext heißt der Wert „Text“', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.prompt);
    final promptId = _nodes(cubit).last.id;
    expect(_nodeById(cubit, promptId).primaryOutputName, 'Text');
    await cubit.renameOutput(
      nodeId: promptId,
      key: WorkflowOutput.primaryOutputKey,
      name: 'Eigener',
    );

    await _switchType(cubit, promptId, PromptOutputType.decision);
    expect(_nodeById(cubit, promptId).primaryOutputName, 'Antwort');

    await _switchType(cubit, promptId, PromptOutputType.text);
    expect(_nodeById(cubit, promptId).primaryOutputName, 'Text');
    await cubit.close();
  });

  test('ist „Antwort“ schon vergeben, wird nummeriert', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.prompt);
    final first = _nodes(cubit).last.id;
    await cubit.addNodeToMainGraph(WorkflowPrimitive.prompt);
    final second = _nodes(cubit).last.id;

    await _switchType(cubit, first, PromptOutputType.decision);
    await _switchType(cubit, second, PromptOutputType.decision);

    expect(_nodeById(cubit, first).primaryOutputName, 'Antwort');
    expect(_nodeById(cubit, second).primaryOutputName, 'Antwort2');
    await cubit.close();
  });

  test('ein nachfolgender Bedingter Ablauf übernimmt den Namen beim '
      'Typwechsel und beim Umbenennen', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.prompt);
    final promptId = _nodes(cubit).last.id;
    await cubit.addNodeToMainGraph(WorkflowPrimitive.conditional);
    final conditionalId = _nodes(cubit).last.id;
    String valueTemplate() =>
        (_nodeById(cubit, conditionalId).config as ConditionalNodeConfig)
            .valueTemplate;

    await _switchType(cubit, promptId, PromptOutputType.decision);
    expect(valueTemplate(), '{{Antwort}}');

    await cubit.renameOutput(
      nodeId: promptId,
      key: WorkflowOutput.primaryOutputKey,
      name: 'Ergebnis',
    );
    expect(valueTemplate(), '{{Ergebnis}}');
    await cubit.close();
  });
}
