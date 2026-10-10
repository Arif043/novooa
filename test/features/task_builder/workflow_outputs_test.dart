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

Map<String, String> _namesOf(WorkflowNode node) => {
  for (final output in node.outputs) output.key: output.name,
};

void main() {
  test('beim Anlegen ist der Hauptwert auf der Leinwand, die übrigen nicht; '
      'alle Namen sind eindeutig und lokalisiert', () async {
    final cubit = await _loadedCubit(_taskWith(_start));

    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);
    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);

    final [_, first, second] = _nodes(cubit);
    expect(_namesOf(first), {
      'value': 'Datensatz',
      'found': 'Gefunden',
      'record': 'Eintrag',
      'message': 'Nachricht',
    });
    expect(first.canvasOutputs.map((output) => output.key), ['value']);
    expect(second.primaryOutputName, 'Datensatz2');
    expect(second.outputNameOf('found'), 'Gefunden2');
    await cubit.close();
  });

  test(
    'Nachricht lesen: Text ist der Hauptwert, Betreff nur bei E-Mail',
    () async {
      final cubit = await _loadedCubit(_taskWith(_start));

      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.email);
      await cubit.addChannelEventNodeToMainGraph(ChannelEventKind.sms);

      final [_, email, sms] = _nodes(cubit);
      expect(_namesOf(email).keys, [
        'value',
        'sender',
        'subject',
        'receivedAt',
      ]);
      expect(email.primaryOutputName, 'Nachricht');
      expect(_namesOf(sms), {
        'value': 'Nachricht2',
        'sender': 'Absender2',
        'receivedAt': 'Empfangen2',
      });
      await cubit.close();
    },
  );

  test('das Flag lässt sich für jeden Wert umschalten', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);
    final nodeId = _nodes(cubit).last.id;

    await cubit.setOutputOnCanvas(
      nodeId: nodeId,
      key: 'found',
      showOnCanvas: true,
    );
    await cubit.setOutputOnCanvas(
      nodeId: nodeId,
      key: 'value',
      showOnCanvas: false,
    );

    final node = _nodes(cubit).last;
    expect(node.canvasOutputs.map((output) => output.key), ['found']);
    await cubit.close();
  });

  test('Umbenennen gilt für Haupt- und weitere Werte; belegte Namen bekommen '
      'eine Nummer', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.documentLookup);
    final nodeId = _nodes(cubit).last.id;

    await cubit.renameOutput(nodeId: nodeId, key: 'value', name: 'Kunde');
    await cubit.renameOutput(nodeId: nodeId, key: 'found', name: 'Treffer');
    await cubit.renameOutput(nodeId: nodeId, key: 'record', name: 'Eingabe');

    final node = _nodes(cubit).last;
    expect(node.primaryOutputName, 'Kunde');
    expect(node.outputNameOf('found'), 'Treffer');
    expect(node.outputNameOf('record'), 'Eingabe_2');
    await cubit.close();
  });

  test('ein Script mit workflow_output tauscht seinen Hauptwert gegen je '
      'einen Wert pro Ausgabe, mit dem Namen aus dem Code', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.script);
    final nodeId = _nodes(cubit).last.id;
    expect(_nodes(cubit).last.primaryOutputName, 'Skript');

    await cubit.updateScript(nodeId, 'workflow_output("summe", "number", 1)');

    expect(_nodes(cubit).last.outputs, const [
      WorkflowOutput(key: 'summe', name: 'summe', showOnCanvas: true),
    ]);
    await cubit.close();
  });

  test(
    'eine andere Aktion bekommt Namen für ihre Werte, alte entfallen',
    () async {
      final shopware = WorkflowNode(
        id: const NodeId('node.shop'),
        title: 'Shopware',
        description: '',
        outputs: const [
          WorkflowOutput.primary('Bestellungen'),
          WorkflowOutput(key: 'count', name: 'Anzahl'),
          WorkflowOutput(key: 'total', name: 'Gesamt'),
          WorkflowOutput(key: 'found', name: 'Gefunden'),
        ],
        config: ShopwareNodeConfig.initial('searchOrders'),
      );
      final cubit = await _loadedCubit(_taskWith(shopware));

      await cubit.updatePluginNode(
        shopware.id,
        (_) => ShopwareNodeConfig.initial('changeOrderStatus'),
      );

      expect(_namesOf(_nodes(cubit).single), {
        'value': 'Bestellungen',
        'previousStatus': 'VorherigerStatus',
        'newStatus': 'NeuerStatus',
        'changed': 'Geaendert',
      });
      await cubit.close();
    },
  );

  test('ein zweiter Dialog behält sein Feld „Antwort“, der Wert heißt '
      '„Antwort2“ und steht auf der Leinwand', () async {
    final cubit = await _loadedCubit(_taskWith(_start));

    await cubit.addNodeToMainGraph(WorkflowPrimitive.dialogInput);
    await cubit.addNodeToMainGraph(WorkflowPrimitive.dialogInput);

    final [_, first, second] = _nodes(cubit);
    final fieldName =
        (second.config as DialogInputNodeConfig).fields.first.name;
    expect(
      (first.config as DialogInputNodeConfig).fields.first.name,
      fieldName,
    );
    expect(first.outputNameOf(fieldName), fieldName);
    expect(second.outputNameOf(fieldName), '${fieldName}2');
    expect(second.canvasOutputs.single.key, fieldName);
    await cubit.close();
  });

  test('Feld umbenennen im Editor erzeugt einen neuen Schlüssel', () async {
    final cubit = await _loadedCubit(_taskWith(_start));
    await cubit.addNodeToMainGraph(WorkflowPrimitive.prompt);
    final nodeId = _nodes(cubit).last.id;
    await cubit.updatePromptOutputType(nodeId, PromptOutputType.structured);
    await cubit.updatePromptStructuredField(
      nodeId: nodeId,
      fieldIndex: 0,
      field: const StructuredOutputField(name: 'summe', description: ''),
    );

    await cubit.updatePromptStructuredField(
      nodeId: nodeId,
      fieldIndex: 0,
      field: const StructuredOutputField(name: 'betrag', description: ''),
    );

    expect(_namesOf(_nodes(cubit).last), {'betrag': 'betrag'});
    await cubit.close();
  });
}
