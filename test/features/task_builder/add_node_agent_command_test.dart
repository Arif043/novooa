import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/agent/add_node_agent_command.dart';
import 'package:syscat2/features/task_builder/presentation/agent/node_field_key.dart';
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

const _emptyTask = Task(
  id: 'task.agent',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.start'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.start'),
        title: 'Start',
        description: 'Beschreibung',
        config: StringInputNodeConfig(value: ''),
      ),
    ],
    edges: [],
  ),
);

WorkflowNode _selectedNode(TaskBuilderCubit cubit) {
  final task = (cubit.state as TaskBuilderLoaded).editingTask;
  return task.nodes.firstWhere((node) => node.id == task.selectedNodeId);
}

void main() {
  test('Script-Vorschlag des Agenten setzt Code und Eingabe', () async {
    final repository = _InMemoryTaskRepository(_emptyTask);
    final cubit = TaskBuilderCubit(repository: repository);
    await cubit.load(repository.savedTask);

    await AddNodeAgentCommand(
      label: 'Summe berechnen',
      primitive: WorkflowPrimitive.script,
      channelKind: ChannelEventKind.email,
      fields: {
        NodeFieldKey.script: 'output = input.upper()',
        NodeFieldKey.inputTemplate: '{{kundenmail.betreff}}',
      },
    ).perform(cubit);

    final config = _selectedNode(cubit).config as ScriptNodeConfig;
    expect(config.script, 'output = input.upper()');
    expect(config.inputTemplate, '{{kundenmail.betreff}}');
    await cubit.close();
  });

  test('Texteingabe-Vorschlag setzt den Wert des neuen Bausteins', () async {
    final repository = _InMemoryTaskRepository(_emptyTask);
    final cubit = TaskBuilderCubit(repository: repository);
    await cubit.load(repository.savedTask);

    await AddNodeAgentCommand(
      label: 'Text',
      primitive: WorkflowPrimitive.stringInput,
      channelKind: ChannelEventKind.email,
      fields: {NodeFieldKey.value: 'Hallo'},
    ).perform(cubit);

    final node = _selectedNode(cubit);
    expect(node.id, isNot(const NodeId('node.start')));
    expect((node.config as StringInputNodeConfig).value, 'Hallo');
    await cubit.close();
  });
}
