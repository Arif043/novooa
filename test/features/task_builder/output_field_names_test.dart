import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_node_config.dart';
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
  outputName: 'Eingabe',
  config: StringInputNodeConfig(value: ''),
);

Future<TaskBuilderCubit> _loadedCubit(Task task) async {
  final cubit = TaskBuilderCubit(repository: _InMemoryTaskRepository(task));
  await cubit.load(task);
  return cubit;
}

List<WorkflowNode> _nodes(TaskBuilderCubit cubit) =>
    (cubit.state as TaskBuilderLoaded).editingTask.nodes;

void main() {
  test('weitere Werte bekommen beim Anlegen eindeutige, lokalisierte Namen '
      'wie ein Hauptwert', () async {
    final cubit = await _loadedCubit(_taskWith(_start));

    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);
    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);

    final [_, first, second] = _nodes(cubit);
    expect(first.outputName, 'Datensatz');
    expect(first.outputFieldNames, {
      'found': 'Gefunden',
      'record': 'Eintrag',
      'message': 'Nachricht',
    });
    expect(second.outputName, 'Datensatz2');
    expect(second.outputFieldNameOf('found'), 'Gefunden2');
    await cubit.close();
  });

  test(
    'Nachricht lesen: Text ist der Hauptwert, Betreff nur bei E-Mail',
    () async {
      final cubit = await _loadedCubit(_taskWith(_start));

      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email);
      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.sms);

      final [_, email, sms] = _nodes(cubit);
      expect(email.outputName, 'Nachricht');
      expect(email.outputFieldNames.keys, ['sender', 'subject', 'receivedAt']);
      expect(sms.outputFieldNames, {
        'sender': 'Absender2',
        'receivedAt': 'Empfangen2',
      });
      await cubit.close();
    },
  );

  test('Umbenennen auf einen belegten Namen hängt eine Nummer an', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);
    final nodeId = _nodes(cubit).last.id;

    await cubit.renameOutputField(
      nodeId: nodeId,
      fieldKey: 'found',
      name: 'Treffer',
    );
    await cubit.renameOutputField(
      nodeId: nodeId,
      fieldKey: 'record',
      name: 'Eingabe',
    );

    final node = _nodes(cubit).last;
    expect(node.outputFieldNameOf('found'), 'Treffer');
    expect(node.outputFieldNameOf('record'), 'Eingabe_2');
    await cubit.close();
  });

  test(
    'eine andere Aktion bekommt Namen für ihre Werte, alte entfallen',
    () async {
      final shopware = WorkflowNode(
        id: const NodeId('node.shop'),
        title: 'Shopware',
        description: '',
        outputName: 'Bestellungen',
        outputFieldNames: const {
          'count': 'Anzahl',
          'total': 'Gesamt',
          'found': 'Gefunden',
        },
        config: ShopwareNodeConfig.initial('searchOrders'),
      );
      final cubit = await _loadedCubit(_taskWith(shopware));

      await cubit.updatePluginNode(
        shopware.id,
        (_) => ShopwareNodeConfig.initial('changeOrderStatus'),
      );

      expect(_nodes(cubit).single.outputFieldNames, {
        'previousStatus': 'VorherigerStatus',
        'newStatus': 'NeuerStatus',
        'changed': 'Geaendert',
      });
      await cubit.close();
    },
  );
}
