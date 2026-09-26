import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_branches_editor.dart';

// Die Auswahl erzeugt die Referenz intern und persistiert sie im Cubit.
void main() {
  Future<TaskBuilderCubit> pumpEditor(WidgetTester tester) async {
    final cubit = TaskBuilderCubit(repository: _FakeTaskRepository(_task()));
    await cubit.load(_task());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(
            body: BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
              builder: (context, state) {
                final node =
                    (state as TaskBuilderLoaded).editingTask.nodes.last;
                return SingleChildScrollView(
                  child: ConditionalBranchesEditor(node: node),
                );
              },
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  ConditionalNodeConfig configOf(TaskBuilderCubit cubit) {
    final state = cubit.state as TaskBuilderLoaded;
    return state.editingTask.nodes.last.config as ConditionalNodeConfig;
  }

  testWidgets('Checkbox entfernt und ergänzt den Sonst-Pfad', (tester) async {
    final cubit = await pumpEditor(tester);
    await cubit.addConditionBranch(const NodeId('conditional.1'));
    await tester.pump();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isTrue,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(configOf(cubit).branches, hasLength(1));
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(configOf(cubit).branches, hasLength(2));
    await cubit.close();
  });

  testWidgets('Gefüllter Sonst-Pfad benötigt Bestätigung', (tester) async {
    final cubit = await pumpEditor(tester);
    await cubit.addConditionBranch(const NodeId('conditional.1'));
    final task = (cubit.state as TaskBuilderLoaded).editingTask;
    final config = configOf(cubit);
    final filled = config.branches.last.copyWith(
      graph: WorkflowGraph(nodes: [task.nodes.first], edges: const []),
    );
    await cubit.repository.saveTask(
      task.copyWith(
        graph: task.graph.copyWith(
          nodes: [
            task.nodes.first,
            task.nodes.last.copyWith(
              config: config.copyWith(
                branches: [config.branches.first, filled],
              ),
            ),
          ],
        ),
      ),
    );
    await cubit.load(task);
    await tester.pump();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(find.text('Sonst-Pfad entfernen?'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(configOf(cubit).branches.last, filled);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pfad entfernen'));
    await tester.pumpAndSettle();
    expect(configOf(cubit).branches, [config.branches.first]);
    await cubit.close();
  });

  testWidgets(
    'Branch hinzufügen, Vergleich eintippen und per Klammer-Aktion zu '
    'einer UND-Gruppe erweitern',
    (tester) async {
      final cubit = await pumpEditor(tester);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Bedingung hinzufügen'),
      );
      await tester.pump();

      expect(configOf(cubit).branches, hasLength(2));
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Texteingabe · eingabe').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('{{'), findsNothing);

      final afterTyping = configOf(cubit).branches[0].condition;
      expect(afterTyping, isA<ComparisonCondition>());
      expect((afterTyping as ComparisonCondition).left, '{{eingabe}}');

      await tester.ensureVisible(find.byIcon(Icons.playlist_add).first);
      await tester.tap(find.byIcon(Icons.playlist_add).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alle Bedingungen müssen zutreffen').last);
      await tester.pumpAndSettle();

      final grouped = configOf(cubit).branches[0].condition;
      expect(grouped, isA<GroupCondition>());
      final group = grouped as GroupCondition;
      expect(group.combinator, BooleanCombinator.and);
      expect(group.children, hasLength(2));
      expect((group.children.first as ComparisonCondition).left, '{{eingabe}}');
      expect(tester.takeException(), isNull);
      await cubit.close();
    },
  );

  testWidgets(
    'Bedingung entfernen kehrt zum branchfreien Ausgangszustand zurück',
    (tester) async {
      final cubit = await pumpEditor(tester);
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Bedingung hinzufügen'),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Bedingung entfernen'));
      await tester.pump();

      expect(configOf(cubit).branches, isEmpty);
      expect(
        find.text(
          'Noch keine Bedingung — ohne Bedingung läuft dieser Baustein '
          'direkt weiter.',
        ),
        findsOneWidget,
      );
      await cubit.close();
    },
  );
}

Task _task() {
  const conditionalId = NodeId('conditional.1');
  return const Task(
    id: 'task',
    title: 'Aufgabe',
    objective: '',
    selectedNodeId: conditionalId,
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('input'),
          title: 'Texteingabe',
          description: '',
          outputName: 'eingabe',
          config: StringInputNodeConfig(value: ''),
        ),
        WorkflowNode(
          id: conditionalId,
          title: 'Bedingter Ablauf',
          description: '',
          config: ConditionalNodeConfig(branches: []),
        ),
      ],
      edges: [WorkflowEdge(from: NodeId('input'), to: conditionalId)],
    ),
  );
}

class _FakeTaskRepository implements TaskRepository {
  _FakeTaskRepository(this.task);

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
