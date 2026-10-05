import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
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
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/baustein_palette.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/read_webhook_widget.dart';

void main() {
  final mapper = NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );

  test('der Baustein wird verlustfrei gespeichert und gelesen', () {
    final document = mapper.toDocument(const ReadWebhookNodeConfig());

    expect(document, {'primitive': 'readWebhook'});
    expect(mapper.fromDocument(document), const ReadWebhookNodeConfig());
  });

  test(
    'feste Ausgaben: Inhalt als JSON, Methode, Query, Kopfzeilen, Zeitpunkt',
    () {
      const config = ReadWebhookNodeConfig();

      expect(primaryOutputTypeOf(config), NodeOutputType.json);
      expect(secondaryOutputFieldsOf(config), [
        'method',
        'query',
        'headers',
        'receivedAt',
      ]);
      expect(secondaryOutputTypeOf('query'), NodeOutputType.json);
      expect(secondaryOutputTypeOf('headers'), NodeOutputType.json);
      expect(secondaryOutputTypeOf('receivedAt'), NodeOutputType.datetime);
      expect(secondaryOutputTypeOf('method'), NodeOutputType.string);
    },
  );

  test(
    'ein neuer Baustein heißt „ereignis“ und hat die passende Konfiguration',
    () async {
      final builder = TaskBuilderCubit(repository: _TaskRepository());
      addTearDown(builder.close);
      await builder.load(_task);
      await builder.addConnectedNode(primitive: WorkflowPrimitive.readWebhook);

      final node =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single;
      expect(node.config, const ReadWebhookNodeConfig());
      expect(node.outputName, startsWith('ereignis'));
    },
  );

  testWidgets(
    'die Palette zeigt den Baustein nur, wenn Webhooks verfügbar sind',
    (tester) async {
      Future<void> pump() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 700,
                child: BausteinPalette(onAdd: (_) {}),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'webhook');
        await tester.pumpAndSettle();
      }

      await pump();
      expect(
        find.text('Webhook-Ereignis'),
        findsNothing,
        reason: 'ohne Fähigkeit (Cloud) ausgeblendet',
      );

      serviceLocator.registerSingleton(_capabilities());
      addTearDown(serviceLocator.reset);
      await pump();
      expect(find.text('EXTERNE SYSTEME'), findsOneWidget);
      expect(find.text('Webhook-Ereignis'), findsOneWidget);
    },
  );

  testWidgets('die Karte erklärt Verwendung und Ausgaben', (tester) async {
    final node = WorkflowNode(
      id: const NodeId('n1'),
      title: 'Webhook-Ereignis',
      description: '',
      outputName: 'ereignis',
      config: const ReadWebhookNodeConfig(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReadWebhookWidget(node: node)),
      ),
    );

    expect(find.textContaining('{{ereignis.bestellung}}'), findsOneWidget);
    expect(find.textContaining('Ausgaben: Inhalt, Methode'), findsOneWidget);
  });
}

WorkspaceCapabilities _capabilities() => const WorkspaceCapabilities(
  assistant: false,
  dataCollections: false,
  modelCatalog: false,
  push: false,
  messagingChannels: false,
  skills: false,
  employees: false,
  connections: false,
  webhooks: true,
);

const _task = Task(
  id: 'task.webhook',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.0'),
  graph: WorkflowGraph(nodes: [], edges: []),
);

class _TaskRepository implements TaskRepository {
  @override
  Stream<List<Task>> watchTasks() => Stream.value([_task]);

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
}
