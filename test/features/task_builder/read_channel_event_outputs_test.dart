import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node_outputs.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_output_types.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/channel_event_output_names_mapper.dart';
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

const _task = Task(
  id: 'task.read',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.start'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.start'),
        title: 'Start',
        description: '',
        config: StringInputNodeConfig(value: ''),
        outputName: 'input1',
      ),
    ],
    edges: [],
  ),
);

Future<TaskBuilderCubit> _loadedCubit() async {
  final cubit = TaskBuilderCubit(repository: _InMemoryTaskRepository(_task));
  await cubit.load(_task);
  return cubit;
}

List<WorkflowNode> _readNodes(TaskBuilderCubit cubit) {
  final task = (cubit.state as TaskBuilderLoaded).editingTask;
  return task.nodes
      .where((node) => node.config is ReadChannelEventNodeConfig)
      .toList();
}

void main() {
  test(
    'Nachricht lesen hat flache, graph-weit eindeutige Hauptoutputs',
    () async {
      final cubit = await _loadedCubit();

      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email);
      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email);

      final [first, second] = _readNodes(cubit);
      expect(first.outputName, isEmpty);
      expect(flatOutputFieldsOf(first.config), [
        'sender',
        'subject',
        'message',
        'receivedAt',
      ]);
      expect(flatOutputFieldsOf(second.config), [
        'sender_2',
        'subject_2',
        'message_2',
        'receivedAt_2',
      ]);
      expect(secondaryOutputFieldsOf(first.config), isEmpty);
      await cubit.close();
    },
  );

  test('Umbenennen hält den Namen eindeutig', () async {
    final cubit = await _loadedCubit();
    await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email);
    final nodeId = _readNodes(cubit).single.id;

    await cubit.renameChannelEventOutputName(
      nodeId: nodeId,
      field: ChannelEventOutputField.sender,
      name: 'Absender',
    );
    await cubit.renameChannelEventOutputName(
      nodeId: nodeId,
      field: ChannelEventOutputField.subject,
      name: 'input1',
    );

    final config =
        _readNodes(cubit).single.config as ReadChannelEventNodeConfig;
    expect(config.outputNames.sender, 'Absender');
    expect(config.outputNames.subject, 'input1_2');
    await cubit.close();
  });

  test('WhatsApp und SMS haben keinen Betreff, Ankunftszeit ist ein Datum', () {
    const config = ReadChannelEventNodeConfig(kind: ChannelEventKind.sms);

    final fields = typedFlatOutputFieldsOf(config);

    expect(fields.map((field) => field.name), [
      'sender',
      'message',
      'receivedAt',
    ]);
    expect(fields.last.type, NodeOutputType.datetime);
  });

  test('Namen werden gespeichert, ohne Angabe gelten die Standardnamen', () {
    final names = const ChannelEventOutputNames().rename(
      ChannelEventOutputField.sender,
      'absender',
    );

    final restored = channelEventOutputNamesFrom(
      channelEventOutputNamesToDocument(names),
    );

    expect(restored, names);
    expect(channelEventOutputNamesFrom(null), const ChannelEventOutputNames());
  });
}
