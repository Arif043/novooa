import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/plugins_scope.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/plugin_node_config.dart';
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
import 'package:syscat2/features/task_builder/presentation/cubits/node_config_labels.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/plugin_node_module.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/baustein_palette.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph_item.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/plugin_disabled_badge.dart';

/// Ein Baustein, wie ihn ein Plugin im eigenen Ordner definieren würde.
class _HelloConfig extends PluginNodeConfig {
  const _HelloConfig({this.name = ''});

  final String name;

  @override
  String get typeId => 'helloPlugin';

  @override
  Map<String, Object?> toDocument() => {'name': name};

  @override
  NodeOutputType get primaryOutputType => NodeOutputType.json;

  @override
  Map<String, NodeOutputType> get outputFields => const {
    'count': NodeOutputType.number,
    'found': NodeOutputType.boolean,
  };

  @override
  List<Object?> get props => [name];
}

PluginNodeModule _module() => PluginNodeModule(
  pluginId: 'hello',
  typeId: 'helloPlugin',
  title: () => 'Hallo-Baustein',
  description: () => 'Sagt Hallo.',
  group: 'Hallo',
  icon: Icons.waving_hand,
  outputBase: 'gruss',
  initial: () => const _HelloConfig(name: 'Welt'),
  fromDocument: (data) => _HelloConfig(name: data['name'] as String? ?? ''),
  builder: (node) => Text('Hallo ${(node.config as _HelloConfig).name}'),
);

const _task = Task(
  id: 'task.plugin',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.0'),
  graph: WorkflowGraph(nodes: [], edges: []),
);

void main() {
  tearDown(() => PluginNodeModules.unregister('helloPlugin'));

  group('Speichern und Laden', () {
    final mapper = NodeConfigDocumentMapper(
      graphToDocument: (_) => const {},
      graphFromDocument: (_) => WorkflowGraph.empty(),
    );

    test(
      'der Baustein trägt seine Kennung als primitive und wird verlustfrei gelesen',
      () {
        PluginNodeModules.register(_module());

        final document = mapper.toDocument(const _HelloConfig(name: 'Anna'));

        expect(document, {'primitive': 'helloPlugin', 'name': 'Anna'});
        expect(mapper.fromDocument(document), const _HelloConfig(name: 'Anna'));
      },
    );

    test(
      'ohne Registrierung fällt das Laden auf die Texteingabe zurück, ohne abzustürzen',
      () {
        expect(
          mapper.fromDocument({'primitive': 'helloPlugin', 'name': 'Anna'}),
          isA<StringInputNodeConfig>(),
        );
      },
    );
  });

  test('Name und Icon der Bausteinart kommen vom Plugin statt „Baustein“', () {
    PluginNodeModules.register(_module());

    expect(const _HelloConfig().label, 'Hallo-Baustein');
    expect(const _HelloConfig().icon, Icons.waving_hand);
  });

  test('Ausgaben und Typen kommen aus der Konfiguration des Plugins', () {
    const config = _HelloConfig();

    expect(config.primitive, WorkflowPrimitive.plugin);
    expect(primaryOutputTypeOf(config), NodeOutputType.json);
    expect(outputFieldsOf(config), ['count', 'found']);
    expect(outputFieldTypeFor(config, 'count'), NodeOutputType.number);
    expect(outputFieldTypeFor(config, 'found'), NodeOutputType.boolean);
    expect(outputFieldTypeFor(config, 'unbekannt'), NodeOutputType.string);
    expect(
      outputFieldTypeFor(StringInputNodeConfig.initial(), 'status'),
      NodeOutputType.number,
    );
  });

  test(
    'ein neuer Baustein bekommt Titel, Ausgabenamen und Anfangskonfiguration des Plugins',
    () async {
      PluginNodeModules.register(_module());
      final builder = TaskBuilderCubit(repository: _TaskRepository());
      addTearDown(builder.close);
      await builder.load(_task);

      await builder.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        pluginTypeId: 'helloPlugin',
      );
      await builder.addConnectedNode(
        primitive: WorkflowPrimitive.plugin,
        pluginTypeId: 'helloPlugin',
      );

      final nodes = (builder.state as TaskBuilderLoaded).editingTask.nodes;
      expect(nodes.map((node) => node.title), [
        'Hallo-Baustein',
        'Hallo-Baustein',
      ]);
      expect(nodes.first.config, const _HelloConfig(name: 'Welt'));
      expect(nodes.first.primaryOutputName, equals('Gruss'));
      expect(nodes.map((node) => node.primaryOutputName).toSet().length, 2);
    },
  );

  group('Palette', () {
    Future<List<BausteinChoice>> pumpPalette(WidgetTester tester) async {
      final added = <BausteinChoice>[];
      await tester.pumpWidget(
        withPlugins(
          enabled: {'hello'},
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 900,
                child: BausteinPalette(onAdd: added.add),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return added;
    }

    testWidgets(
      'zeigt den Baustein in der Gruppe des Plugins und fügt ihn mit seiner Kennung hinzu',
      (tester) async {
        PluginNodeModules.register(_module());
        final added = await pumpPalette(tester);

        // Die Liste baut nur Sichtbares; die Suche holt die Plugin-Gruppe nach vorn.
        await tester.enterText(find.byType(TextField), 'hallo');
        await tester.pumpAndSettle();

        expect(find.text('HALLO'), findsOneWidget);
        expect(find.byIcon(Icons.waving_hand), findsOneWidget);
        await tester.tap(find.text('Hallo-Baustein'));

        expect(added.single.pluginTypeId, 'helloPlugin');
        expect(added.single.primitive, WorkflowPrimitive.plugin);
      },
    );

    testWidgets('findet Plugin-Bausteine über die Suche', (tester) async {
      PluginNodeModules.register(_module());
      await pumpPalette(tester);
      await tester.enterText(find.byType(TextField), 'hallo');
      await tester.pumpAndSettle();
      expect(find.text('Hallo-Baustein'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('Hallo-Baustein'), findsNothing);
    });
  });

  group('Leinwand', () {
    Future<void> pumpNode(
      WidgetTester tester,
      PluginNodeConfig config, {
      Set<String> enabled = const {'hello'},
    }) async {
      final builder = TaskBuilderCubit(repository: _TaskRepository());

      await tester.pumpWidget(
        withPlugins(
          enabled: enabled,
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: builder,
                child: NodeGraphItem(
                  node: WorkflowNode(
                    id: const NodeId('n1'),
                    title: 'Hallo-Baustein',
                    description: '',
                    outputs: [WorkflowOutput.primary('gruss1')],
                    config: config,
                  ),
                  dragSourceNodeIds: const {},
                  isSource: false,
                  isDragActive: false,
                  onDragStarted: () {},
                  onDragEnded: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('zeigt das Widget des Plugins', (tester) async {
      PluginNodeModules.register(_module());
      await pumpNode(tester, const _HelloConfig(name: 'Anna'));

      expect(find.text('Hallo Anna'), findsOneWidget);
      expect(find.textContaining('Plugin deaktiviert'), findsNothing);
    });

    testWidgets('ein deaktiviertes Plugin zeigt Formular und Hinweis', (
      tester,
    ) async {
      PluginNodeModules.register(_module());
      await pumpNode(tester, const _HelloConfig(name: 'Anna'), enabled: {});

      expect(find.text('Hallo Anna'), findsOneWidget);
      expect(find.textContaining('Plugin deaktiviert'), findsOneWidget);
    });

    for (final (enabled, badges) in [
      (<String>{}, findsOneWidget),
      ({'hello'}, findsNothing),
    ]) {
      testWidgets('Ausrufezeichen nur bei deaktiviertem Plugin ($enabled)', (
        tester,
      ) async {
        PluginNodeModules.register(_module());
        await tester.pumpWidget(
          withPlugins(
            enabled: enabled,
            MaterialApp(
              home: PluginDisabledBadge(
                node: WorkflowNode(
                  id: const NodeId('n1'),
                  title: 'Hallo-Baustein',
                  description: '',
                  outputs: [WorkflowOutput.primary('gruss1')],
                  config: const _HelloConfig(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.priority_high), badges);
      });
    }

    testWidgets('ein Baustein ohne registriertes Plugin zeigt einen Hinweis', (
      tester,
    ) async {
      await pumpNode(tester, const _HelloConfig(name: 'Anna'));

      expect(find.text('Dieser Baustein ist nicht verfügbar.'), findsOneWidget);
    });
  });
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
