import 'package:flutter/widgets.dart';
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

import '../../helpers/test_translations.dart';

class _Repository implements TaskRepository {
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

const _task = Task(
  id: 'task.names',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.start'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.start'),
        title: 'Start',
        description: '',
        config: StringInputNodeConfig(value: ''),
      ),
    ],
    edges: [],
  ),
);

Future<WorkflowNode> _addedNode(
  Future<void> Function(TaskBuilderCubit cubit) add,
) async {
  final cubit = TaskBuilderCubit(repository: _Repository());
  await cubit.load(_task);
  await add(cubit);
  final task = (cubit.state as TaskBuilderLoaded).editingTask;
  final node = task.nodes.last;
  await cubit.close();
  return node;
}

void main() {
  tearDown(() => loadTestTranslations(const Locale('de')));

  test('neue Bausteine bekommen deutsche Standardnamen und -titel', () async {
    final node = await _addedNode(
      (cubit) => cubit.addNodeToMainGraph(WorkflowPrimitive.prompt),
    );

    expect(node.outputName, 'anweisung1');
    expect(node.title, 'Prompt');
  });

  test('neue Bausteine bekommen englische Standardnamen und -titel', () async {
    loadTestTranslations(const Locale('en'));

    final node = await _addedNode(
      (cubit) => cubit.addNodeToMainGraph(WorkflowPrimitive.stringInput),
    );

    expect(node.outputName, 'input1');
    expect(node.title, 'Text input');
  });

  test('Sendebausteine nutzen Kanal und Sprache im Namen', () async {
    final german = await _addedNode(
      (cubit) => cubit.addSendMessageNodeToMainGraph(ChannelEventKind.email),
    );
    loadTestTranslations(const Locale('en'));
    final english = await _addedNode(
      (cubit) => cubit.addSendMessageNodeToMainGraph(ChannelEventKind.email),
    );

    expect(german.outputName, 'sendenemail1');
    expect(german.title, 'E-Mail senden');
    expect(english.outputName, 'sendemail1');
    expect(english.title, 'Send Email');
  });
}
