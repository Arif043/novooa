import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
import 'package:syscat2/features/connections/domain/entities/connection.dart';
import 'package:syscat2/features/connections/domain/entities/connection_draft.dart';
import 'package:syscat2/features/connections/domain/entities/connection_failure.dart';
import 'package:syscat2/features/connections/domain/entities/connection_test_result.dart';
import 'package:syscat2/features/connections/domain/repositories/connection_repository.dart';
import 'package:syscat2/features/connections/domain/usecases/connection_use_cases.dart';
import 'package:syscat2/features/connections/presentation/cubits/connections_cubit.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_actions.dart';
import 'package:syscat2/features/integrations/shopware/domain/shopware_node_config.dart';
import 'package:syscat2/features/integrations/shopware/presentation/widgets/shopware_action_widget.dart';
import 'package:syscat2/features/integrations/shopware/shopware_plugin.dart';
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
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/baustein_palette.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _shop = Connection(
  id: 'c1',
  name: 'Mein Shop',
  baseUrl: 'https://shop.example.com',
  auth: BearerAuth(),
  updatedAt: 'x',
);

const _searchOrders = 'shopware.searchOrders';

void main() {
  setUp(registerShopwarePlugin);
  tearDown(() async {
    PluginNodeModules.unregister(_searchOrders);
    await serviceLocator.reset();
  });

  final mapper = NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );

  group('Speichern und Laden', () {
    test(
      'die Aktion wird als Primitive shopware mit action und params gespeichert',
      () {
        final config = ShopwareNodeConfig.initial(
          'searchOrders',
        ).copyWith(connectionId: 'c1').withParam('status', 'open');

        final document = mapper.toDocument(config);

        expect(document, {
          'primitive': 'shopware',
          'action': 'searchOrders',
          'connectionId': 'c1',
          'params': {'sort': 'newest', 'limit': 50, 'status': 'open'},
        });
        expect(mapper.fromDocument(document), config);
      },
    );

    test('ohne Verbindung steht keine connectionId im Dokument', () {
      final document = mapper.toDocument(
        ShopwareNodeConfig.initial('searchOrders'),
      );

      expect(document.containsKey('connectionId'), isFalse);
    });

    test('leere Eingaben entfallen, damit das Dokument schlank bleibt', () {
      final config = ShopwareNodeConfig.initial(
        'searchOrders',
      ).withParam('orderNumber', '10001').withParam('orderNumber', '');

      expect(config.params.containsKey('orderNumber'), isFalse);
    });

    test('eine unbekannte Aktion bleibt erhalten, statt verloren zu gehen', () {
      final restored = mapper.fromDocument({
        'primitive': 'shopware',
        'action': 'kommtSpaeter',
        'params': {'x': 1},
      });

      expect(restored, isA<ShopwareNodeConfig>());
      expect((restored as ShopwareNodeConfig).action, 'kommtSpaeter');
      expect(restored.params, {'x': 1});
      expect(mapper.toDocument(restored)['action'], 'kommtSpaeter');
    });
  });

  test(
    'Ausgaben: Liste als JSON, Anzahl, Gesamtzahl und found mit passendem Typ',
    () {
      final config = ShopwareNodeConfig.initial('searchOrders');

      expect(primaryOutputTypeOf(config), NodeOutputType.json);
      expect(secondaryOutputFieldsOf(config), ['count', 'total', 'found']);
      expect(secondaryOutputTypeFor(config, 'count'), NodeOutputType.number);
      expect(secondaryOutputTypeFor(config, 'total'), NodeOutputType.number);
      expect(secondaryOutputTypeFor(config, 'found'), NodeOutputType.boolean);
    },
  );

  test(
    'die Felder der Aktion sind im Formular beschrieben und das Limit hat Grenzen',
    () {
      final keys = ShopwareActions.searchOrders.fields.map(
        (field) => field.key,
      );

      expect(keys, [
        'createdFrom',
        'createdTo',
        'status',
        'paymentStatus',
        'deliveryStatus',
        'customerEmail',
        'orderNumber',
        'sort',
        'limit',
      ]);
      expect(
        ShopwareActions.byId('searchOrders'),
        same(ShopwareActions.searchOrders),
      );
      expect(ShopwareActions.byId('gibtEsNicht'), isNull);
    },
  );

  test(
    'ein neuer Baustein bekommt Titel, Ausgabenamen und Voreinstellungen der Aktion',
    () async {
      final builder = TaskBuilderCubit(repository: _TaskRepository());
      addTearDown(builder.close);
      await builder.load(_task);

      await builder.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        pluginTypeId: _searchOrders,
      );

      final node =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single;
      expect(node.title, 'Bestellungen suchen');
      expect(node.outputName, startsWith('bestellungen'));
      expect(node.config, isA<ShopwareNodeConfig>());
      expect((node.config as ShopwareNodeConfig).params, {
        'sort': 'newest',
        'limit': 50,
      });
    },
  );

  group('Palette', () {
    Future<List<BausteinChoice>> pump(WidgetTester tester) async {
      final added = <BausteinChoice>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 900,
              child: BausteinPalette(onAdd: added.add),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'bestellungen');
      await tester.pumpAndSettle();
      return added;
    }

    testWidgets(
      'zeigt die Aktion in der Gruppe Shopware, wo es Verbindungen gibt',
      (tester) async {
        serviceLocator.registerSingleton(_capabilities(connections: true));
        final added = await pump(tester);

        expect(find.text('SHOPWARE'), findsOneWidget);
        expect(find.text('Bestellungen suchen'), findsOneWidget);
        await tester.tap(find.text('Bestellungen suchen'));
        expect(added.single.pluginTypeId, _searchOrders);
      },
    );

    testWidgets('fehlt ohne Verbindungen, z. B. in der Cloud', (tester) async {
      serviceLocator.registerSingleton(_capabilities(connections: false));
      await pump(tester);

      expect(find.text('Bestellungen suchen'), findsNothing);
    });
  });

  group('Formular', () {
    late TaskBuilderCubit builder;
    late _TaskRepository tasks;

    setUp(() {
      tasks = _TaskRepository();
      builder = TaskBuilderCubit(repository: tasks);
      serviceLocator.registerSingleton(_capabilities(connections: true));
    });

    Future<void> pumpNode(
      WidgetTester tester, {
      List<Connection> connections = const [_shop],
      ShopwareNodeConfig? config,
    }) async {
      await builder.load(_task);
      await builder.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        pluginTypeId: _searchOrders,
      );
      final id =
          (builder.state as TaskBuilderLoaded).editingTask.nodes.single.id;
      if (config != null) await builder.updatePluginNode(id, (_) => config);
      final connectionsCubit = ConnectionsCubit(
        WatchConnections(_ConnectionRepository(connections)),
        CreateConnection(_ConnectionRepository(connections)),
        UpdateConnection(_ConnectionRepository(connections)),
        DeleteConnection(_ConnectionRepository(connections)),
        TestConnection(_ConnectionRepository(connections)),
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
                  builder: (context, state) => ShopwareActionWidget(
                    node: (state as TaskBuilderLoaded).editingTask.nodes.single,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Der Cubit speichert verzögert (800 ms); das läuft vor dem Ende aus, sonst bliebe ein Timer offen.
    void widgetTest(
      String description,
      Future<void> Function(WidgetTester) body,
    ) {
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }

    ShopwareNodeConfig current() =>
        (builder.state as TaskBuilderLoaded).editingTask.nodes.single.config
            as ShopwareNodeConfig;

    widgetTest('zeigt Titel, Verbindung und alle Felder der Aktion', (
      tester,
    ) async {
      await pumpNode(tester);

      expect(find.text('Bestellungen suchen'), findsOneWidget);
      for (final label in [
        'Verbindung',
        'Bestellt ab',
        'Bestellt bis',
        'Bestellstatus',
        'Zahlungsstatus',
        'Lieferstatus',
        'E-Mail des Kunden',
        'Bestellnummer',
        'Reihenfolge',
        'Höchstanzahl',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      expect(find.text('Neueste zuerst'), findsOneWidget);
    });

    widgetTest(
      'ohne Verbindungen weist ein Hinweis auf die Vorlage Shopware hin',
      (tester) async {
        await pumpNode(tester, connections: const []);

        expect(find.textContaining('Vorlage'), findsOneWidget);
      },
    );

    widgetTest('Textfelder landen in params, leeren entfernt den Eintrag', (
      tester,
    ) async {
      await pumpNode(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Bestellt ab'),
        '{{start}}',
      );
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, 'E-Mail des Kunden'),
        'anna@example.com',
      );
      await tester.pump();
      expect(current().params['createdFrom'], '{{start}}');
      expect(current().params['customerEmail'], 'anna@example.com');

      await tester.enterText(
        find.widgetWithText(TextField, 'E-Mail des Kunden'),
        '',
      );
      await tester.pump();
      expect(current().params.containsKey('customerEmail'), isFalse);
    });

    widgetTest('die Höchstanzahl wird auf 1 bis 500 begrenzt', (tester) async {
      await pumpNode(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Höchstanzahl'),
        '9999',
      );
      await tester.pump();
      expect(current().params['limit'], 500);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Höchstanzahl'),
        '0',
      );
      await tester.pump();
      expect(current().params['limit'], 1);
    });

    widgetTest(
      'eine Auswahl wird gespeichert; „Beliebig“ entfernt den Filter',
      (tester) async {
        await pumpNode(
          tester,
          config: ShopwareNodeConfig.initial(
            'searchOrders',
          ).withParam('status', 'open'),
        );
        expect(find.text('Offen'), findsOneWidget);

        await tester.tap(find.text('Offen'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Beliebig').last);
        await tester.pump();

        expect(current().params.containsKey('status'), isFalse);
      },
    );

    widgetTest('die Verbindung wird gewählt; eine gelöschte bleibt sichtbar', (
      tester,
    ) async {
      await pumpNode(tester);
      await tester.tap(find.text('Verbindung'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mein Shop').last);
      await tester.pump();
      expect(current().connectionId, 'c1');

      await pumpNode(
        tester,
        config: ShopwareNodeConfig.initial(
          'searchOrders',
        ).copyWith(connectionId: 'weg'),
      );
      expect(find.text('Verbindung nicht gefunden'), findsOneWidget);
      expect(current().connectionId, 'weg');
    });

    widgetTest(
      'eine unbekannte Aktion zeigt einen Hinweis statt eines Formulars',
      (tester) async {
        await builder.load(_task);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider.value(
              value: builder,
              child: ShopwareActionWidget(
                node: WorkflowNode(
                  id: const NodeId('n1'),
                  title: 'Shopware',
                  description: '',
                  outputName: 'x',
                  config: const ShopwareNodeConfig(action: 'kommtSpaeter'),
                ),
              ),
            ),
          ),
        );

        expect(
          find.textContaining('kennt diese Version von novooa nicht'),
          findsOneWidget,
        );
        expect(find.text('Verbindung'), findsNothing);
      },
    );
  });
}

WorkspaceCapabilities _capabilities({required bool connections}) =>
    WorkspaceCapabilities(
      assistant: false,
      dataCollections: false,
      modelCatalog: false,
      push: false,
      messagingChannels: false,
      skills: false,
      employees: false,
      connections: connections,
      webhooks: false,
    );

const _task = Task(
  id: 'task.shopware',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.0'),
  graph: WorkflowGraph(nodes: [], edges: []),
);

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
