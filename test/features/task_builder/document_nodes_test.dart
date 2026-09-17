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
import 'package:syscat2/features/task_builder/presentation/widgets/document_lookup_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/save_document_widget.dart';

void main() {
  test('aktualisiert alle Konfigurationswerte für Datensatz suchen', () async {
    final cubit = await _cubitFor(_lookupTask());
    const nodeId = NodeId('lookup');
    await cubit.updateDocumentLookupCollection(nodeId, 'kunden');
    await cubit.updateDocumentLookupFilter(
      nodeId,
      0,
      const DocumentLookupFilter(
        field: 'email',
        operator: DocumentFilterOperator.equals,
        value: '{{nachricht.sender}}',
      ),
    );
    await cubit.addDocumentLookupFilter(nodeId);
    await cubit.removeDocumentLookupFilter(nodeId, 1);

    final config =
        _taskOf(cubit).nodes.single.config as DocumentLookupNodeConfig;
    expect(config.collectionName, 'kunden');
    expect(config.filters, hasLength(1));
    expect(config.filters.single.field, 'email');
    await cubit.close();
  });

  test(
    'aktualisiert alle Konfigurationswerte für Datensatz speichern',
    () async {
      final cubit = await _cubitFor(_saveTask());
      const nodeId = NodeId('save');
      await cubit.updateSaveDocumentCollection(nodeId, 'bestellungen');
      await cubit.addSaveDocumentFilter(nodeId);
      await cubit.updateSaveDocumentFilter(
        nodeId,
        0,
        const DocumentLookupFilter(
          field: 'bestellnummer',
          operator: DocumentFilterOperator.equals,
          value: '{{eingang.bestellnummer}}',
        ),
      );
      await cubit.addSaveDocumentFilter(nodeId);
      await cubit.removeSaveDocumentFilter(nodeId, 1);
      await cubit.updateSaveDocumentField(
        nodeId,
        0,
        const DocumentFieldAssignment(field: 'status', value: 'bezahlt'),
      );
      await cubit.addSaveDocumentField(nodeId);
      await cubit.removeSaveDocumentField(nodeId, 1);

      final config =
          _taskOf(cubit).nodes.single.config as SaveDocumentNodeConfig;
      expect(config.collectionName, 'bestellungen');
      expect(config.filters.single.field, 'bestellnummer');
      expect(config.fields, const [
        DocumentFieldAssignment(field: 'status', value: 'bezahlt'),
      ]);
      await cubit.close();
    },
  );

  testWidgets('zeigt und erweitert Suchbedingungen', (tester) async {
    final cubit = await _cubitFor(_lookupTask());
    await tester.pumpWidget(
      _host(cubit, (task) => DocumentLookupWidget(node: task.nodes.single)),
    );

    expect(find.text('Datensatz suchen'), findsOneWidget);
    await tester.tap(find.text('Bedingung hinzufügen'));
    await tester.pump();

    expect(find.byType(DocumentLookupWidget), findsOneWidget);
    expect(find.bySemanticsLabel('Suchbedingung 2'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('zeigt Speicherbedingungen und ergänzt Felder', (tester) async {
    final cubit = await _cubitFor(_saveTask());
    await tester.pumpWidget(
      _host(cubit, (task) => SaveDocumentWidget(node: task.nodes.single)),
    );

    expect(find.text('Datensatz speichern'), findsOneWidget);
    expect(find.text('Modus: Anlegen'), findsOneWidget);
    final addField = find.text('Feld hinzufügen');
    await tester.ensureVisible(addField);
    await tester.tap(addField);
    await tester.pump();

    expect(find.bySemanticsLabel('Feldzuordnung 2'), findsOneWidget);
    await cubit.close();
  });
}

Future<TaskBuilderCubit> _cubitFor(Task task) async {
  final cubit = TaskBuilderCubit(repository: _TaskRepository(task));
  await cubit.load(task);
  return cubit;
}

Task _taskOf(TaskBuilderCubit cubit) {
  return (cubit.state as TaskBuilderLoaded).editingTask;
}

Widget _host(TaskBuilderCubit cubit, Widget Function(Task task) child) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider.value(
        value: cubit,
        child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
          builder: (context, state) {
            final task = (state as TaskBuilderLoaded).editingTask;
            return child(task);
          },
        ),
      ),
    ),
  );
}

Task _lookupTask() {
  return _task(
    const WorkflowNode(
      id: NodeId('lookup'),
      title: 'Datensatz suchen',
      description: '',
      config: DocumentLookupNodeConfig(
        collectionName: '',
        filters: [
          DocumentLookupFilter(
            field: '',
            operator: DocumentFilterOperator.equals,
            value: '',
          ),
        ],
      ),
    ),
  );
}

Task _saveTask() {
  return _task(
    const WorkflowNode(
      id: NodeId('save'),
      title: 'Datensatz speichern',
      description: '',
      config: SaveDocumentNodeConfig(
        collectionName: '',
        filters: [],
        fields: [DocumentFieldAssignment(field: '', value: '')],
      ),
    ),
  );
}

Task _task(WorkflowNode node) {
  return Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: node.id,
    graph: WorkflowGraph(nodes: [node], edges: const []),
  );
}

class _TaskRepository implements TaskRepository {
  _TaskRepository(this.task);

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
