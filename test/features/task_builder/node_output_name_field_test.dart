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
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_name_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, WorkflowNode node) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NodeOutputNameField(node: node)),
      ),
    );
  }

  testWidgets('zeigt den Ausgabenamen als Chip für einen einfachen Baustein', (
    tester,
  ) async {
    await pump(
      tester,
      const WorkflowNode(
        id: NodeId('n1'),
        title: '',
        description: '',
        outputName: 'eingang',
        config: StringInputNodeConfig(value: ''),
      ),
    );

    expect(find.text('eingang'), findsOneWidget);
  });

  testWidgets('bleibt ausgeblendet ohne Ausgabename', (tester) async {
    await pump(
      tester,
      const WorkflowNode(
        id: NodeId('n1'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      ),
    );

    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets(
    'blendet sich für strukturierte Prompt-Ausgaben aus, auch mit gesetztem outputName',
    (tester) async {
      await pump(
        tester,
        const WorkflowNode(
          id: NodeId('n1'),
          title: '',
          description: '',
          outputName: 'prompt1',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.structured,
            choices: [],
            structuredFields: [
              StructuredOutputField(name: 'Name', description: ''),
            ],
          ),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
    },
  );

  testWidgets(
    'blendet sich für Dialogeingabe aus, auch mit gesetztem outputName',
    (tester) async {
      await pump(
        tester,
        const WorkflowNode(
          id: NodeId('n1'),
          title: '',
          description: '',
          outputName: 'dialog1',
          config: DialogInputNodeConfig(
            instruction: '',
            fields: [
              DialogInputField(
                name: 'Kundennummer',
                type: DialogInputFieldType.string,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
    },
  );

  testWidgets('speichert einen geänderten Ausgabenamen ohne die '
      '"TextEditingController used after being disposed"-Exception '
      '(Regressionstest)', (tester) async {
    const node = WorkflowNode(
      id: NodeId('n1'),
      title: '',
      description: '',
      outputName: 'eingang',
      config: StringInputNodeConfig(value: ''),
    );
    final cubit = await _cubitFor(_taskFor(node));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: const NodeOutputNameField(node: node),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InputChip));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ausgang');
    await tester.tap(find.text('Speichern'));
    // Durchläuft die Cupertino-Schließanimation des Dialogs vollständig —
    // genau in diesem Fenster trat die Exception auf, bevor der Dialog
    // seinen Controller selbst besaß.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final state = cubit.state as TaskBuilderLoaded;
    expect(state.editingTask.nodes.single.outputName, 'ausgang');
    await cubit.close();
  });
}

Future<TaskBuilderCubit> _cubitFor(Task task) async {
  final cubit = TaskBuilderCubit(repository: _TaskRepository(task));
  await cubit.load(task);
  return cubit;
}

Task _taskFor(WorkflowNode node) {
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
