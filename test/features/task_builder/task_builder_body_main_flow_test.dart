import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
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
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_header.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_builder_theme.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_title_field.dart';

// Eigene Datei statt eines weiteren Tests in workflow_workspace_test.dart:
// derselbe Ablauf hing dort zuverlässig in pumpAndSettle(), lief isoliert
// aber sofort durch — ein Anzeichen für Testverschmutzung (vermutlich ein
// nicht abgeräumter Ticker/Timer) aus einem der vorangehenden, sehr
// umfangreichen Widget-Tests in dieser Datei, nicht für einen echten Fehler
// in diesem Test oder im geprüften Verhalten.
void main() {
  testWidgets(
    'ein Klick im Bausteine-Menü fügt ohne gewählten Einfügepunkt in den '
    'Hauptfluss ein — als direkten Nachfolger des fokussierten Bausteins, '
    'nicht als zusätzlichen parallelen Zweig',
    (tester) async {
      tester.view.physicalSize = const Size(1480, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = TaskBuilderCubit(repository: _Repository());
      addTearDown(cubit.close);
      await cubit.load(_task);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: TaskBuilderTheme.from(SyscatTheme.lightTheme),
            home: Scaffold(
              body: Column(
                children: [
                  TaskBuilderHeader(
                    title: const TaskTitleField(),
                    onMenuPressed: () {},
                    actions: const SizedBox.shrink(),
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
      );
      // "text" auf der Leinwand fokussieren — wie in der echten Bedienung,
      // ohne einen "+"-Verbindungspunkt anzutippen.
      await tester.tap(find.byKey(const ValueKey('compact-node-text')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Konfiguration schließen'));
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

      final task = (cubit.state as TaskBuilderLoaded).editingTask;
      final insertedId = task.nodes.last.id;
      expect(task.nodes.last.config.primitive, WorkflowPrimitive.script);
      // "text" bekommt genau eine ausgehende Kante — zum neuen Baustein.
      // "decision" hängt jetzt daran, statt weiterhin direkt an "text" zu
      // hängen (kein dritter, paralleler Zweig).
      expect(
        task.graph.outgoingEdgesOf(const NodeId('text')).map((e) => e.to),
        [insertedId],
      );
      expect(
        task.graph.outgoingEdgesOf(insertedId).map((e) => e.to),
        [const NodeId('decision')],
      );
      expect(tester.takeException(), isNull);
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
        outputName: 'text',
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
