import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/domain/entities/connection_draft.dart';
import 'package:syscat2/features/connections/domain/entities/connection_failure.dart';
import 'package:syscat2/features/connections/domain/entities/connection_test_result.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
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
import 'package:syscat2/features/task_builder/presentation/widgets/http_request_widget.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _shop = Connection(
  id: 'c1',
  name: 'Shopware',
  baseUrl: 'https://shop.example.com/api',
  auth: BearerAuth(),
  updatedAt: 'x',
);

const _post = HttpRequestNodeConfig(
  connectionId: 'c1',
  method: HttpRequestMethod.post,
  url: '/search/order',
  query: [HttpNameValue(name: 'limit', value: '10')],
  headers: [HttpNameValue(name: 'X-Kunde', value: '{{kunde}}')],
  bodyType: HttpBodyType.json,
  body: '{"kunde": "{{kunde}}"}',
  timeoutSeconds: 45,
  failOnHttpError: false,
);

void main() {
  group('HttpRequestNodeConfig', () {
    final mapper = NodeConfigDocumentMapper(
      graphToDocument: (_) => const {},
      graphFromDocument: (_) => WorkflowGraph.empty(),
    );

    test('wird verlustfrei gespeichert und gelesen', () {
      final document = mapper.toDocument(_post);

      expect(document['primitive'], 'httpRequest');
      expect(document['method'], 'POST');
      expect(mapper.fromDocument(document), _post);
    });

    test('ohne Verbindung wird keine connectionId gespeichert', () {
      final document = mapper.toDocument(const HttpRequestNodeConfig());

      expect(document.containsKey('connectionId'), isFalse);
      expect(mapper.fromDocument(document), const HttpRequestNodeConfig());
    });

    test('fehlende oder unbekannte Felder ergeben die Standardwerte', () {
      final restored = mapper.fromDocument({
        'primitive': 'httpRequest',
        'method': 'TRACE',
        'bodyType': 'xml',
        'query': [
          {'name': 'a'},
          'kaputt',
        ],
      });

      expect(
        restored,
        const HttpRequestNodeConfig(query: [HttpNameValue(name: 'a')]),
      );
    });

    test('nur Methoden mit Body senden einen', () {
      expect(HttpRequestMethod.get.sendsBody, isFalse);
      for (final method in HttpRequestMethod.values.skip(1)) {
        expect(method.sendsBody, isTrue, reason: method.wire);
      }
    });
  });

  group('Ausgaben', () {
    test('status, ok und headers sind feste Felder mit passendem Typ', () {
      expect(outputFieldsOf(const HttpRequestNodeConfig()), [
        'status',
        'ok',
        'headers',
      ]);
      expect(outputFieldTypeOf('status'), NodeOutputType.number);
      expect(outputFieldTypeOf('ok'), NodeOutputType.boolean);
      expect(outputFieldTypeOf('headers'), NodeOutputType.json);
      expect(
        primaryOutputTypeOf(const HttpRequestNodeConfig()),
        NodeOutputType.json,
      );
    });
  });

  group('TaskBuilderCubit', () {
    test(
      'fügt den Baustein mit eindeutigem Ausgabenamen ein und ändert ihn',
      () async {
        final repository = _TaskRepository();
        final cubit = TaskBuilderCubit(repository: repository);
        await cubit.load(repository.saved);

        await cubit.addConnectedNode(primitive: WorkflowPrimitive.httpRequest);
        await cubit.addConnectedNode(primitive: WorkflowPrimitive.httpRequest);

        final nodes = (cubit.state as TaskBuilderLoaded).editingTask.nodes;
        expect(nodes.map((node) => node.title), [
          'HTTP-Anfrage',
          'HTTP-Anfrage',
        ]);
        expect(nodes.map((node) => node.primaryOutputName).toSet().length, 2);
        expect(nodes.first.primaryOutputName, equals('Antwort'));
        expect(nodes.first.config, const HttpRequestNodeConfig());

        await cubit.updateHttpRequest(
          nodes.first.id,
          (config) =>
              config.copyWith(url: '/orders', method: HttpRequestMethod.post),
        );
        final changed =
            (cubit.state as TaskBuilderLoaded).editingTask.nodes.first.config
                as HttpRequestNodeConfig;
        expect(changed.url, '/orders');
        expect(changed.method, HttpRequestMethod.post);
        expect(
          (cubit.state as TaskBuilderLoaded).editingTask.nodes.last.config,
          const HttpRequestNodeConfig(),
          reason: 'der andere Baustein bleibt unverändert',
        );
        await cubit.close();
      },
    );
  });

  group('Widgets', () {
    late _ConnectionRepository connections;
    late TaskBuilderCubit builder;
    late _TaskRepository tasks;

    setUp(() {
      connections = _ConnectionRepository(const [_shop]);
      tasks = _TaskRepository();
      builder = TaskBuilderCubit(repository: tasks);
    });

    tearDown(() async {
      await serviceLocator.reset();
    });

    Future<ConnectionsCubit> pumpNode(
      WidgetTester tester,
      HttpRequestNodeConfig config,
    ) async {
      await builder.load(tasks.saved);
      await builder.addConnectedNode(primitive: WorkflowPrimitive.httpRequest);
      final id =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single.id;
      await builder.updateHttpRequest(id, (_) => config);
      final connectionsCubit = ConnectionsCubit(
        WatchConnections(connections),
        CreateConnection(connections),
        UpdateConnection(connections),
        DeleteConnection(connections),
        TestConnection(connections),
        GetCurrentTeamId(_Teams()),
      );
      addTearDown(connectionsCubit.close);
      await connectionsCubit.load();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: builder),
            BlocProvider.value(value: connectionsCubit),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
                  builder: (context, state) => HttpRequestWidget(
                    node: (state as TaskBuilderLoaded).editingTask.nodes.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Begrenzt statt pumpAndSettle: Die Textfelder animieren ihre Höhe.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      return connectionsCubit;
    }

    // Der Cubit speichert verzögert; vor der Prüfung auf offene Timer muss das ablaufen.
    void widgetTest(
      String description,
      Future<void> Function(WidgetTester) body,
    ) {
      testWidgets(description, (tester) async {
        await body(tester);
        // Die verzögerte Speicherung (800 ms) läuft aus, sonst bliebe ein Timer offen.
        // (Der Cubit wird hier nicht geschlossen: close() wartet in der Fake-Zeit nie.)
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    HttpRequestNodeConfig current() =>
        (builder.state as TaskBuilderLoaded).editingTask.nodes.single.config
            as HttpRequestNodeConfig;

    widgetTest('mit Verbindung heißt das Feld „Pfad“, ohne „URL“', (
      tester,
    ) async {
      await pumpNode(tester, _post);
      expect(find.widgetWithText(TextField, 'Pfad'), findsOneWidget);
      expect(find.text('Shopware'), findsOneWidget);

      await pumpNode(tester, const HttpRequestNodeConfig());
      expect(find.widgetWithText(TextField, 'URL'), findsOneWidget);
    });

    widgetTest('zeigt die Zieladresse aus Basis-URL und Pfad', (tester) async {
      await pumpNode(tester, _post);
      expect(
        find.text(
          'https://shop.example.com/api/search/order',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.enterText(find.widgetWithText(TextField, 'Pfad'), 'kunden');
      await tester.pump();
      expect(
        find.text('https://shop.example.com/api/kunden', findRichText: true),
        findsOneWidget,
      );
    });

    widgetTest('ohne Verbindung steht der Hinweis zur Anmeldung darunter', (
      tester,
    ) async {
      await pumpNode(tester, const HttpRequestNodeConfig());

      expect(
        find.text('Ohne Verbindung wird ohne Anmeldung gesendet.'),
        findsOneWidget,
      );
    });

    widgetTest(
      'eine gelöschte Verbindung bleibt sichtbar statt zu verschwinden',
      (tester) async {
        await pumpNode(
          tester,
          const HttpRequestNodeConfig(connectionId: 'weg'),
        );

        expect(find.text('Verbindung nicht gefunden'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Pfad'), findsOneWidget);
        expect(
          find.text('Relativ zur Basis-URL der Verbindung.'),
          findsOneWidget,
        );
        expect(current().connectionId, 'weg');
      },
    );

    widgetTest('Eingaben landen in der Konfiguration', (tester) async {
      await pumpNode(tester, _post);

      await tester.enterText(find.widgetWithText(TextField, 'Pfad'), '/neu');
      await tester.pump();

      expect(current().url, '/neu');
      expect(current().connectionId, 'c1');
    });

    widgetTest('Header und Parameter lassen sich hinzufügen und entfernen', (
      tester,
    ) async {
      await pumpNode(tester, const HttpRequestNodeConfig());

      await tester.tap(find.text('Header hinzufügen'));
      await tester.pump();
      expect(current().headers, [const HttpNameValue()]);

      await tester.tap(find.text('Parameter hinzufügen'));
      await tester.pump();
      await tester.tap(find.text('Parameter hinzufügen'));
      await tester.pump();
      expect(current().query.length, 2);

      await tester.tap(find.byTooltip('Entfernen').first);
      await tester.pump();
      expect(current().query.length, 1);
      expect(current().headers.length, 1);
    });

    widgetTest('der Body erscheint nur für Methoden, die einen senden', (
      tester,
    ) async {
      await pumpNode(tester, const HttpRequestNodeConfig());
      expect(find.text('Kein Body'), findsNothing);

      await pumpNode(tester, _post);
      expect(find.text('Kein Body'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Body'), findsOneWidget);
    });

    widgetTest(
      'Zeitlimit wird auf 1 bis 120 begrenzt, Fehlerstatus-Schalter wirkt',
      (tester) async {
        await pumpNode(tester, _post);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Zeitlimit (Sekunden)'),
          '999',
        );
        await tester.pump();
        expect(current().timeoutSeconds, 120);

        await tester.ensureVisible(find.byType(Switch));
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(current().failOnHttpError, isTrue);
      },
    );
  });

  group('Palette', () {
    testWidgets('der Baustein erscheint unter Externe Systeme', (tester) async {
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
        await tester.enterText(find.byType(TextField), 'http');
        await tester.pumpAndSettle();
      }

      await pump();
      expect(find.text('EXTERNE SYSTEME'), findsOneWidget);
      expect(find.text('HTTP-Anfrage'), findsOneWidget);
    });
  });
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _ConnectionRepository implements ConnectionRepository {
  _ConnectionRepository(this.connections);

  final List<Connection> connections;

  @override
  Stream<List<Connection>> watchConnections(TeamId teamId) =>
      Stream.value(connections);

  @override
  Future<Result<Connection, ConnectionFailure>> create(
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Connection, ConnectionFailure>> update(
    String id,
    ConnectionDraft draft,
  ) async => const Success(_shop);

  @override
  Future<Result<Unit, ConnectionFailure>> delete(String id) async =>
      const Success(unit);

  @override
  Future<Result<ConnectionTestResult, ConnectionFailure>> test(
    String id, {
    String path = '',
  }) async => const Success(ConnectionTestResult(ok: true, message: 'ok'));
}

class _TaskRepository implements TaskRepository {
  Task saved = const Task(
    id: 'task.http',
    title: 'Aufgabe',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.0'),
    graph: WorkflowGraph(nodes: [], edges: []),
  );

  @override
  Stream<List<Task>> watchTasks() => Stream.value([saved]);

  @override
  Future<void> saveTask(Task task) async => saved = task;

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => const Error(TaskRunFailure(TaskRunFailureKind.executionFailed));
}
