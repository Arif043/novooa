import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_body.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_configuration_panel.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/workflow_canvas_layout.dart';

void main() {
  test('layout preserves actual edges and exposes named branch entries', () {
    final layout = WorkflowCanvasLayout(_task.graph);
    expect(
      layout.links.where(
        (link) => link.from == 'text' && link.to == 'decision',
      ),
      hasLength(1),
    );
    expect(layout.links.where((link) => link.label == 'Ja'), hasLength(1));
    expect(layout.links.where((link) => link.label == 'Nein'), hasLength(1));
    expect(
      layout.rectangles['decision']!.top,
      greaterThan(layout.rectangles['text']!.bottom),
    );
    final disconnected = WorkflowCanvasLayout(
      WorkflowGraph(nodes: _task.nodes, edges: const []),
    );
    expect(disconnected.links.where((link) => link.from == 'text'), isEmpty);
  });

  test(
    'connects selected predecessors and preserves channel in nested branches',
    () async {
      final cubit = TaskBuilderCubit(repository: _Repository());
      addTearDown(cubit.close);
      await cubit.load(_task);
      await cubit.addConnectedNode(
        primitive: .sendChannelMessage,
        ownerId: const NodeId('decision'),
        branchId: 'yes',
        channelKind: .whatsapp,
      );
      final task = (cubit.state as TaskBuilderLoaded).editingTask;
      final branch =
          (task.nodes.last.config as ConditionalNodeConfig).branches.first;
      expect(
        (branch.graph.nodes.single.config as SendChannelMessageNodeConfig).kind,
        ChannelEventKind.whatsapp,
      );
      await cubit.addConnectedNode(
        primitive: .stringInput,
        afterId: const NodeId('text'),
      );
      final updated = (cubit.state as TaskBuilderLoaded).editingTask;
      expect(updated.edges.last.from, const NodeId('text'));
      expect(updated.edges.last.to, updated.nodes.last.id);
      expect(updated.edges.first, _task.edges.first);
    },
  );

  testWidgets(
    'palette, compact nodes and live configuration overlay work together',
    (tester) async {
      tester.view.physicalSize = const Size(1480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = TaskBuilderCubit(repository: _Repository());
      await cubit.load(_task);
      final captureKey = GlobalKey();
      if (const bool.fromEnvironment('CAPTURE_WORKSPACE')) {
        await tester.runAsync(() async {
          final fontPath = Platform.environment['WORKSPACE_PREVIEW_FONT'];
          if (fontPath != null) {
            final bytes = await File(fontPath).readAsBytes();
            await (FontLoader(
              'Roboto',
            )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFFF9500),
              ),
              useMaterial3: true,
            ),
            home: Scaffold(
              body: RepaintBoundary(
                key: captureKey,
                child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
                  builder: (_, state) => TaskBuilderBody(state: state),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(NodeConfigurationPanel), findsNothing);
      expect(find.widgetWithText(TextField, 'Text eingeben'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('compact-node-text')));
      await tester.pumpAndSettle();
      expect(find.byType(NodeConfigurationPanel), findsOneWidget);
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'Text eingeben',
        ),
        'Aktualisierter Text',
      );
      await tester.pumpAndSettle();
      expect(
        ((cubit.state as TaskBuilderLoaded).editingTask.nodes.first.config
                as StringInputNodeConfig)
            .value,
        'Aktualisierter Text',
      );
      if (const bool.fromEnvironment('CAPTURE_WORKSPACE')) {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '/tmp/novooa-builder-preview.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('Konfiguration schließen'));
      await tester.pumpAndSettle();
      expect(find.byType(NodeConfigurationPanel), findsNothing);
      await tester.enterText(find.byType(TextField), 'Script');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Script'));
      await tester.pumpAndSettle();
      expect(
        (cubit.state as TaskBuilderLoaded)
            .editingTask
            .nodes
            .last
            .config
            .primitive,
        WorkflowPrimitive.script,
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Bausteine'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );
}

const _task = Task(
  id: 'workspace',
  title: 'Arbeitsplan',
  objective: '',
  selectedNodeId: NodeId('text'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('text'),
        title: 'Text',
        description: '',
        referenceName: 'text',
        config: StringInputNodeConfig(value: 'Beispiel'),
      ),
      WorkflowNode(
        id: NodeId('decision'),
        title: 'Bedingung',
        description: '',
        config: ConditionalNodeConfig(
          branches: [
            ConditionalBranch(
              id: 'yes',
              label: 'Ja',
              graph: WorkflowGraph(nodes: [], edges: []),
            ),
            ConditionalBranch(
              id: 'no',
              label: 'Nein',
              graph: WorkflowGraph(nodes: [], edges: []),
            ),
          ],
        ),
      ),
    ],
    edges: [WorkflowEdge(from: NodeId('text'), to: NodeId('decision'))],
  ),
);

class _Repository implements TaskRepository {
  @override
  Future<void> deleteTask(String taskId) async {}
  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async => throw UnimplementedError();
  @override
  Stream<List<Task>> watchTasks() => Stream.value(const [_task]);
  @override
  Future<void> saveTask(Task task) async {}
}
