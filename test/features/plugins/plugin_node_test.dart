import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/plugins/domain/entities/installed_plugin.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_failure.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_manifest.dart';
import 'package:syscat2/features/plugins/domain/entities/plugin_settings.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:syscat2/features/plugins/domain/usecases/plugin_use_cases.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_registry_cubit.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/baustein_palette.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_chips.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/plugin_baustein_choices.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/plugin_node_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

const _manifest = PluginManifest(
  id: 'hallo',
  version: '1.0.0',
  name: 'Hallo-Plugin',
  description: '',
  primitives: [
    PluginPrimitiveDefinition(
      type: 'greet',
      label: 'Begrüßen',
      description: 'Erzeugt einen Gruß.',
      group: 'Beispiele',
      settings: [
        PluginField(
          key: 'name',
          label: 'Name',
          kind: PluginFieldKind.template,
        ),
        PluginField(
          key: 'times',
          label: 'Anzahl',
          kind: PluginFieldKind.number,
          defaultValue: 1,
        ),
      ],
      outputs: [
        PluginOutputDefinition(
          name: 'value',
          label: 'Gruß',
          type: PluginOutputType.string,
        ),
        PluginOutputDefinition(
          name: 'length',
          label: 'Länge',
          type: PluginOutputType.number,
        ),
      ],
    ),
  ],
);

const _seed = PluginNodeSeed(
  pluginId: 'hallo',
  nodeType: 'greet',
  title: 'Begrüßen',
  description: 'Erzeugt einen Gruß.',
  settings: {'times': 1},
);

void main() {
  group('PluginNodeConfig', () {
    final mapper = NodeConfigDocumentMapper(
      graphToDocument: (_) => const {},
      graphFromDocument: (_) => WorkflowGraph.empty(),
    );

    test('wird verlustfrei gespeichert und gelesen', () {
      const config = PluginNodeConfig(
        pluginId: 'hallo',
        nodeType: 'greet',
        settings: {'name': '{{kunde}}', 'times': 2, 'loud': true},
      );

      final document = mapper.toDocument(config);

      expect(document['primitive'], 'plugin');
      expect(mapper.fromDocument(document), config);
    });

    test('ungültige Einstellungen werden beim Lesen verworfen', () {
      final restored = mapper.fromDocument({
        'primitive': 'plugin',
        'pluginId': 'hallo',
        'nodeType': 'greet',
        'settings': {'ok': 'x', 'kaputt': <String>[], 'nichts': null},
      });

      expect((restored as PluginNodeConfig).settings, {'ok': 'x'});
    });

    test('fehlende Felder ergeben eine leere, ladbare Konfiguration', () {
      expect(
        mapper.fromDocument({'primitive': 'plugin'}),
        PluginNodeConfig.initial(),
      );
    });
  });

  group('Palette', () {
    test('gruppiert Plugin-Bausteine nach Manifest und setzt Standardwerte', () {
      final groups = pluginBausteinGroups([_manifest]);

      expect(groups.keys, ['Beispiele']);
      final choice = groups['Beispiele']!.single;
      expect(choice.label, 'Begrüßen');
      expect(choice.primitive, WorkflowPrimitive.plugin);
      expect(choice.plugin!.settings, {'times': 1});
    });

    test('Bausteine ohne Gruppe landen unter „Plugins“', () {
      const manifest = PluginManifest(
        id: 'x',
        version: '1.0.0',
        name: 'X',
        description: '',
        primitives: [
          PluginPrimitiveDefinition(type: 'a', label: 'A', description: ''),
        ],
      );

      expect(pluginBausteinGroups([manifest]).keys, ['Plugins']);
    });
  });

  group('TaskBuilderCubit', () {
    test('fügt einen Plugin-Baustein mit eindeutigem Ausgabenamen ein', () async {
      final repository = _Repository(_emptyTask());
      final cubit = TaskBuilderCubit(repository: repository);
      await cubit.load(repository.saved);

      await cubit.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        plugin: _seed,
      );
      await cubit.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        plugin: _seed,
      );

      final nodes = (cubit.state as TaskBuilderLoaded).editingTask.nodes;
      expect(nodes.map((node) => node.title), ['Begrüßen', 'Begrüßen']);
      expect(nodes.first.config, _seed.config);
      expect(nodes.map((node) => node.outputName).toSet().length, 2);
      expect(nodes.first.outputName, startsWith('greet'));
      await cubit.close();
    });

    test('updatePluginNode ändert nur die gewünschte Einstellung', () async {
      final repository = _Repository(_emptyTask());
      final cubit = TaskBuilderCubit(repository: repository);
      await cubit.load(repository.saved);
      await cubit.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        plugin: _seed,
      );
      final id = (cubit.state as TaskBuilderLoaded).editingTask.nodes.single.id;

      await cubit.updatePluginNode(id, (config) => config.withSetting('name', 'Anna'));

      final config =
          (cubit.state as TaskBuilderLoaded).editingTask.nodes.single.config
              as PluginNodeConfig;
      expect(config.settings, {'times': 1, 'name': 'Anna'});
      expect(config.pluginId, 'hallo');
      await cubit.close();
    });
  });

  group('Ausgaben', () {
    final node = WorkflowNode(
      id: const NodeId('node.1'),
      title: 'Begrüßen',
      description: '',
      outputName: 'greet1',
      config: _seed.config,
    );

    test('Nebenoutputs ohne value, mit Typ aus dem Manifest', () {
      final fields = pluginSecondaryFields([_manifest], _seed.config);

      expect(fields, [(name: 'length', type: NodeOutputType.number)]);
    });

    test('ohne Plugin gibt es keine Nebenoutputs', () {
      expect(pluginSecondaryFields(const [], _seed.config), isEmpty);
    });

    test('die #-Suche schlägt Plugin-Ausgaben vor', () {
      final graph = WorkflowGraph(
        nodes: [
          node,
          const WorkflowNode(
            id: NodeId('node.2'),
            title: 'Nachfolger',
            description: '',
            outputName: 'next',
            config: StringInputNodeConfig(value: ''),
          ),
        ],
        edges: const [
          WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.2')),
        ],
      );

      final expressions = templateExpressionSuggestions(
        graph: graph,
        targetNodeId: const NodeId('node.2'),
        pluginManifests: [_manifest],
      ).map((suggestion) => suggestion.expression);

      expect(expressions, contains('{{greet1.length}}'));
    });
  });

  group('Widgets', () {
    final node = WorkflowNode(
      id: const NodeId('node.1'),
      title: 'Begrüßen',
      description: '',
      outputName: 'greet1',
      config: _seed.config,
    );
    late PluginRegistryCubit registry;

    setUp(() {
      serviceLocator.registerSingleton(
        const WorkspaceCapabilities(
          assistant: false,
          dataCollections: false,
          modelCatalog: false,
          push: false,
          messagingChannels: false,
          skills: false,
          employees: false,
          plugins: true,
        ),
      );
    });

    tearDown(() async {
      await registry.close();
      await serviceLocator.reset();
    });

    Future<void> pump(
      WidgetTester tester,
      Widget child, {
      List<InstalledPlugin> installed = const [InstalledPlugin(manifest: _manifest)],
    }) async {
      final repository = _PluginRepository(installed);
      registry = PluginRegistryCubit(
        WatchPlugins(repository),
        GetCurrentTeamId(_Teams()),
      );
      await registry.ensureLoaded();
      await tester.pumpWidget(
        BlocProvider.value(
          value: registry,
          child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('der Baustein rendert die Felder aus dem Manifest', (tester) async {
      await pump(tester, BlocProvider(
        create: (_) => TaskBuilderCubit(repository: _Repository(_emptyTask())),
        child: PluginNodeWidget(node: node),
      ));

      expect(find.text('Begrüßen'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Anzahl'), findsOneWidget);
    });

    testWidgets('ohne das Plugin erklärt der Baustein, was fehlt', (tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => TaskBuilderCubit(repository: _Repository(_emptyTask())),
          child: PluginNodeWidget(node: node),
        ),
        installed: const [],
      );

      expect(find.textContaining('nicht installiert'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('die Palette zeigt installierte Plugin-Bausteine in ihrer Gruppe', (tester) async {
      await pump(tester, SizedBox(height: 600, child: BausteinPalette(onAdd: (_) {})));

      // Die Liste baut nur sichtbare Einträge; die Suche holt die Plugin-Gruppe nach oben.
      await tester.enterText(find.byType(TextField), 'begrüßen');
      await tester.pumpAndSettle();

      expect(find.text('BEISPIELE'), findsOneWidget);
      expect(find.text('Begrüßen'), findsOneWidget);
      expect(find.text('DATEN'), findsNothing);
    });

    testWidgets('die Output-Chips nennen die Nebenoutputs des Plugins', (tester) async {
      await pump(tester, NodeOutputChips(node: node));

      expect(find.text('length'), findsOneWidget);
      expect(find.text('value'), findsNothing);
    });
  });
}

Task _emptyTask() => const Task(
  id: 'task.plugins',
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

class _PluginRepository implements PluginRepository {
  _PluginRepository(this.plugins);

  final List<InstalledPlugin> plugins;

  @override
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId) => Stream.value(plugins);

  @override
  Future<Result<Unit, PluginFailure>> uninstall(String pluginId) async => const Success(unit);

  @override
  Future<Result<PluginSettings, PluginFailure>> settings(String pluginId) async =>
      const Success(PluginSettings());

  @override
  Future<Result<Unit, PluginFailure>> saveSettings(String pluginId, Map<String, Object> values) async =>
      const Success(unit);
}

class _Repository implements TaskRepository {
  _Repository(this.saved);

  Task saved;

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
