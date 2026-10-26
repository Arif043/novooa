import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/plugins_scope.dart';
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
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_theme.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_header.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_title_field.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

List<String> _texts(List<CanvasLabel> labels) =>
    labels.map((label) => label.text).toList();

void main() {
  test('an uneven Ja path retains its column through the final insertion', () {
    const child = WorkflowNode(
      id: NodeId('yes-child'),
      title: '',
      description: '',
      config: StringInputNodeConfig(value: ''),
    );
    final decision = _task.nodes.last.copyWith(
      config: const ConditionalNodeConfig(
        branches: [
          ConditionalBranch(
            id: 'yes',
            label: 'Ja',
            graph: WorkflowGraph(nodes: [child], edges: []),
          ),
          ConditionalBranch(
            id: 'no',
            label: 'Nein',
            graph: WorkflowGraph(nodes: [], edges: []),
          ),
        ],
      ),
    );
    final layout = WorkflowCanvasLayout(
      WorkflowGraph(nodes: [decision], edges: const []),
    );
    final yes = layout.rectangles['yes-child']!;
    final append = layout.rectangles['@append:yes-child']!;
    final no = layout.rectangles['@empty:decision:no']!;
    final continuation = layout.rectangles['@continue:decision']!;
    expect(append.left, yes.left);
    expect(append.top, greaterThan(yes.bottom));
    expect(yes.right, lessThan(no.left));
    expect(continuation.center.dx, layout.rectangles['decision']!.center.dx);
    expect(continuation.top, greaterThan(append.bottom));
    expect(continuation.top, greaterThan(no.bottom));
  });

  test('layout preserves actual edges and exposes named branch entries', () {
    final layout = WorkflowCanvasLayout(_task.graph);
    expect(
      layout.links.where(
        (link) => link.from == 'text' && link.to == 'decision',
      ),
      hasLength(1),
    );
    expect(
      layout.links
          .firstWhere((link) => link.from == 'text' && link.to == 'decision')
          .isCondition,
      isFalse,
    );
    expect(
      layout.links.where(
        (link) => link.labels.any((label) => label.text == 'Text ist Ja'),
      ),
      hasLength(1),
    );
    expect(
      layout.links.where(
        (link) => link.labels.any((label) => label.text == 'Text ist Nein'),
      ),
      hasLength(1),
    );
    expect(
      layout.links
          .where(
            (link) => link.labels.any((label) => label.text == 'Text ist Ja'),
          )
          .single
          .isCondition,
      isTrue,
    );
    expect(
      layout.rectangles['decision']!.top,
      greaterThan(layout.rectangles['text']!.bottom),
    );
    final disconnected = WorkflowCanvasLayout(
      WorkflowGraph(nodes: _task.nodes, edges: const []),
    );
    expect(
      disconnected.links.where(
        (link) => link.from == 'text' && link.to == 'decision',
      ),
      isEmpty,
    );
    expect(
      disconnected.entries['@append:text']!.insertion.after,
      const NodeId('text'),
    );
  });

  test(
    'zeigt den Ausgabenamen als Chip auf dem Ausgangspfeil eines Bausteins',
    () {
      expect(
        _texts(
          WorkflowCanvasLayout(_task.graph).links
              .firstWhere(
                (link) => link.from == 'text' && link.to == 'decision',
              )
              .labels,
        ),
        ['text'],
      );
      const withoutOutputName = WorkflowNode(
        id: NodeId('anon'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      const successor = WorkflowNode(
        id: NodeId('next'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      final plainLayout = WorkflowCanvasLayout(
        const WorkflowGraph(
          nodes: [withoutOutputName, successor],
          edges: [WorkflowEdge(from: NodeId('anon'), to: NodeId('next'))],
        ),
      );
      expect(
        plainLayout.links
            .firstWhere((link) => link.from == 'anon' && link.to == 'next')
            .labels,
        isEmpty,
      );
      const withConditionLabel = WorkflowNode(
        id: NodeId('branching'),
        title: '',
        description: '',
        outputs: [WorkflowOutput.primary('branching')],
        config: StringInputNodeConfig(value: ''),
      );
      final overriddenLayout = WorkflowCanvasLayout(
        WorkflowGraph(
          nodes: const [withConditionLabel, successor],
          edges: const [
            WorkflowEdge(
              from: NodeId('branching'),
              to: NodeId('next'),
              conditionLabel: 'Ja',
            ),
          ],
        ),
      );
      expect(
        _texts(
          overriddenLayout.links
              .firstWhere(
                (link) => link.from == 'branching' && link.to == 'next',
              )
              .labels,
        ),
        ['Ja'],
      );
    },
  );

  test('zeigt für strukturierte Prompt-Ausgaben einen Chip pro Feld', () {
    const promptNode = WorkflowNode(
      id: NodeId('prompt2'),
      title: '',
      description: '',
      outputs: [
        WorkflowOutput(key: 'Name', name: 'Name', showOnCanvas: true),
        WorkflowOutput(key: 'Alter', name: 'Alter', showOnCanvas: true),
      ],
      config: PromptNodeConfig(
        instruction: '',
        outputType: PromptOutputType.structured,
        choices: [],
        structuredFields: [
          StructuredOutputField(name: 'Name', description: ''),
          StructuredOutputField(name: 'Alter', description: ''),
        ],
      ),
    );
    const successor = WorkflowNode(
      id: NodeId('next'),
      title: '',
      description: '',
      config: StringInputNodeConfig(value: ''),
    );
    final layout = WorkflowCanvasLayout(
      const WorkflowGraph(
        nodes: [promptNode, successor],
        edges: [WorkflowEdge(from: NodeId('prompt2'), to: NodeId('next'))],
      ),
    );
    expect(
      _texts(
        layout.links
            .firstWhere((link) => link.from == 'prompt2' && link.to == 'next')
            .labels,
      ),
      ['Name', 'Alter'],
    );
  });

  test('verlängert den Pfeil, je mehr Chips darauf gestapelt werden', () {
    double gapFor(List<String> fieldNames) {
      final promptNode = WorkflowNode(
        id: const NodeId('prompt'),
        title: '',
        description: '',
        outputs: [
          for (final name in fieldNames)
            WorkflowOutput(key: name, name: name, showOnCanvas: true),
        ],
        config: PromptNodeConfig(
          instruction: '',
          outputType: PromptOutputType.structured,
          choices: const [],
          structuredFields: fieldNames.isEmpty
              ? const [StructuredOutputField(name: '', description: '')]
              : [
                  for (final name in fieldNames)
                    StructuredOutputField(name: name, description: ''),
                ],
        ),
      );
      const successor = WorkflowNode(
        id: NodeId('next'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      );
      final layout = WorkflowCanvasLayout(
        WorkflowGraph(
          nodes: [promptNode, successor],
          edges: const [
            WorkflowEdge(from: NodeId('prompt'), to: NodeId('next')),
          ],
        ),
      );
      return layout.rectangles['next']!.top -
          layout.rectangles['prompt']!.bottom;
    }

    final oneLabelGap = gapFor([]);
    final twoLabelGap = gapFor(['Name', 'Alter']);
    final threeLabelGap = gapFor(['Name', 'Alter', 'Beruf']);
    expect(twoLabelGap, greaterThan(oneLabelGap));
    expect(threeLabelGap, greaterThan(twoLabelGap));
  });

  test(
    'every branch ends with an insertion and continuation follows the longest nested branch',
    () {
      final left = WorkflowNode(
        id: const NodeId('left'),
        title: '',
        description: '',
        config: const StringInputNodeConfig(value: ''),
      );
      final nested = WorkflowNode(
        id: const NodeId('nested'),
        title: '',
        description: '',
        config: ConditionalNodeConfig.initial(),
      );
      final decision = _task.nodes.last.copyWith(
        config: ConditionalNodeConfig(
          branches: [
            ConditionalBranch(
              id: 'yes',
              label: 'Ja',
              graph: WorkflowGraph(
                nodes: [left, nested],
                edges: const [
                  WorkflowEdge(from: NodeId('left'), to: NodeId('nested')),
                ],
              ),
            ),
            const ConditionalBranch(
              id: 'no',
              label: 'Nein',
              graph: WorkflowGraph(nodes: [], edges: []),
            ),
          ],
        ),
      );
      final next = WorkflowNode(
        id: const NodeId('next'),
        title: '',
        description: '',
        config: const StringInputNodeConfig(value: ''),
      );
      final layout = WorkflowCanvasLayout(
        WorkflowGraph(
          nodes: [decision, next],
          edges: const [
            WorkflowEdge(from: NodeId('decision'), to: NodeId('next')),
          ],
        ),
      );
      final nestedInsertion = layout.entries['@continue:nested']!.insertion;
      expect(
        layout.rectangles['left']!.center.dx,
        layout.rectangles['nested']!.center.dx,
      );
      expect(
        layout.rectangles['nested']!.center.dx,
        layout.rectangles['@continue:nested']!.center.dx,
      );
      expect(
        layout.rectangles['decision']!.center.dx,
        layout.rectangles['@continue:decision']!.center.dx,
      );
      expect(
        layout.rectangles['next']!.center.dx,
        layout.rectangles['decision']!.center.dx,
      );
      expect(nestedInsertion.owner, decision.id);
      expect(nestedInsertion.branchId, 'yes');
      expect(nestedInsertion.after, nested.id);
      final continuation = layout.entries['@continue:decision']!.insertion;
      expect(continuation.owner, isNull);
      expect(continuation.after, decision.id);
      expect(
        layout.rectangles['@continue:decision']!.top,
        greaterThan(layout.rectangles['@continue:nested']!.bottom),
      );
      expect(
        layout.rectangles['next']!.top,
        greaterThan(layout.rectangles['@continue:decision']!.bottom),
      );
      expect(layout.entries['@append:next']!.insertion.after, next.id);
      final plainBranch = decision.copyWith(
        config: ConditionalNodeConfig(
          branches: [
            ConditionalBranch(
              id: 'yes',
              label: 'Ja',
              graph: WorkflowGraph(nodes: [left], edges: const []),
            ),
          ],
        ),
      );
      final plainLayout = WorkflowCanvasLayout(
        WorkflowGraph(nodes: [plainBranch], edges: const []),
      );
      expect(plainLayout.entries['@append:left']!.insertion.owner, decision.id);
      expect(plainLayout.entries['@append:left']!.insertion.branchId, 'yes');
      expect(plainLayout.entries['@append:left']!.insertion.after, left.id);
    },
  );

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
      final insertedId = updated.nodes.last.id;
      // "text" bekommt genau einen direkten Nachfolger — den neuen Baustein
      // —, dessen vorige Kante zu "decision" wird auf den neuen Baustein
      // gespleißt, statt als zusätzlicher paralleler Zweig neben ihm stehen
      // zu bleiben (siehe WorkflowGraph.addNode).
      expect(updated.edges.last.from, const NodeId('text'));
      expect(updated.edges.last.to, insertedId);
      expect(updated.edges.first.from, insertedId);
      expect(updated.edges.first.to, const NodeId('decision'));
      expect(updated.edges, isNot(contains(_task.edges.first)));
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
              'Inter',
            )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      await tester.pumpWidget(
        withPlugins(
          BlocProvider.value(
            value: cubit,
            child: MaterialApp(
              theme: TaskBuilderTheme.from(SyscatTheme.lightTheme),
              home: Scaffold(
                body: RepaintBoundary(
                  key: captureKey,
                  child: Column(
                    children: [
                      TaskBuilderHeader(
                        title: const TaskTitleField(),
                        onMenuPressed: () {},
                        actions: const _HeaderActions(),
                      ),
                      Expanded(
                        child: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
                          builder: (_, state) => TaskBuilderBody(state: state),
                        ),
                      ),
                    ],
                  ),
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
      await tester.tap(find.byTooltip('Gesamten Arbeitsplan anzeigen'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('path-insertion-@continue:decision')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Bausteine suchen',
        ),
        'Script',
      );
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
      expect(
        find.byKey(const ValueKey('path-insertion-@continue:decision')),
        findsNothing,
      );
      expect(find.text('Nach der Bedingung'), findsOneWidget);
      final insertedId =
          (cubit.state as TaskBuilderLoaded).editingTask.nodes.last.id;
      expect(
        find.byKey(ValueKey('path-insertion-@append:${insertedId.value}')),
        findsOneWidget,
      );
      expect(
        (cubit.state as TaskBuilderLoaded).editingTask.edges.last.from,
        const NodeId('decision'),
      );
      expect(tester.takeException(), isNull);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bausteine'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );

  testWidgets(
    'header retains editable title at small widths and large text in both themes',
    (tester) async {
      final cubit = TaskBuilderCubit(repository: _Repository());
      await cubit.load(_task);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final dark in [false, true]) {
        for (final size in [
          const Size(375, 812),
          const Size(812, 375),
          const Size(1280, 900),
        ]) {
          tester.view.physicalSize = size;
          await tester.pumpWidget(
            BlocProvider.value(
              value: cubit,
              child: MaterialApp(
                theme: TaskBuilderTheme.from(
                  dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(2),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: Column(
                    children: [
                      TaskBuilderHeader(
                        title: const TaskTitleField(),
                        onMenuPressed: () {},
                        actions: const _HeaderActions(),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.enterText(find.byType(TextField), 'Rechnung prüfen');
          await tester.pump();
          expect(
            (cubit.state as TaskBuilderLoaded).editingTask.title,
            'Rechnung prüfen',
          );
        }
      }
      await cubit.close();
    },
  );
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'KI-Agent',
        onPressed: () {},
        icon: const Icon(Icons.auto_awesome_outlined),
      ),
      IconButton(
        tooltip: 'Benachrichtigungen',
        onPressed: () {},
        icon: const Icon(Icons.notifications_outlined),
      ),
    ],
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
        outputs: [WorkflowOutput.primary('text')],
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
              condition: ComparisonCondition(
                left: '{{Text}}',
                operator: ComparisonOperator.equals,
                right: 'Ja',
              ),
            ),
            ConditionalBranch(
              id: 'no',
              label: 'Nein',
              graph: WorkflowGraph(nodes: [], edges: []),
              condition: ComparisonCondition(
                left: '{{Text}}',
                operator: ComparisonOperator.equals,
                right: 'Nein',
              ),
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
