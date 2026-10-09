import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_action_suggestion.dart';
import 'package:syscat2/features/assistant/presentation/agent/assistant_plan_executor.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_performer.dart';
import 'package:syscat2/features/assistant/presentation/cursor/agent_cursor_target.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_agent_command_factory.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';

class _InMemoryTaskRepository implements TaskRepository {
  _InMemoryTaskRepository(this.savedTask);

  Task savedTask;

  @override
  Stream<List<Task>> watchTasks() => Stream.value([savedTask]);

  @override
  Future<void> saveTask(Task task) async {
    savedTask = task;
  }

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

const _emptyTask = Task(
  id: 'task.agent',
  title: 'Aufgabe',
  objective: 'Ziel',
  selectedNodeId: NodeId('node.start'),
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.start'),
        title: 'Start',
        description: 'Beschreibung',
        config: StringInputNodeConfig(value: ''),
      ),
    ],
    edges: [],
  ),
);

WorkflowNode _selectedNode(TaskBuilderCubit cubit) {
  final task = (cubit.state as TaskBuilderLoaded).editingTask;
  return task.nodes.firstWhere((node) => node.id == task.selectedNodeId);
}

class _RecordingCursor implements AgentCursorPerformer {
  final events = <String>[];

  @override
  Future<void> begin() async => events.add('begin');

  @override
  Future<void> moveTo(AgentCursorTarget target) async =>
      events.add('move ${target.key}');

  @override
  Future<bool> click(AgentCursorTarget target) async {
    events.add('click ${target.key}');
    return true;
  }

  @override
  Future<void> typeInto(
    AgentCursorTarget target,
    String text,
    AgentCursorTextChanged onTextChanged,
  ) async {
    events.add('type ${target.key}');
    await onTextChanged(text);
  }

  @override
  void hide() => events.add('hide');
}

AssistantActionSuggestion _suggestion(
  String type,
  Map<String, Object?> arguments,
) {
  return AssistantActionSuggestion(
    target: AssistantActionTarget.taskBuilder,
    type: type,
    label: type,
    arguments: arguments,
  );
}

void main() {
  test('configureNode befüllt einen im Plan angelegten Baustein', () async {
    final cubit = TaskBuilderCubit(
      repository: _InMemoryTaskRepository(_emptyTask),
    );
    await cubit.load(_emptyTask);
    final actions = TaskBuilderAgentCommandFactory(waitForFrame: () async {})
        .fromSuggestions([
          _suggestion('addNode', {'primitive': 'prompt', 'ref': 'a'}),
          _suggestion('configureNode', {
            'nodeRef': 'a',
            'fields': {'instruction': 'Fasse zusammen'},
          }),
        ], cubit);

    await const AssistantPlanExecutor(
      stepDelay: Duration.zero,
    ).execute(actions);

    final config = _selectedNode(cubit).config as PromptNodeConfig;
    expect(config.instruction, 'Fasse zusammen');
    await cubit.close();
  });

  test('Script-Felder werden bei anderen Bausteinen verworfen', () async {
    final cubit = TaskBuilderCubit(
      repository: _InMemoryTaskRepository(_emptyTask),
    );
    final actions = TaskBuilderAgentCommandFactory(waitForFrame: () async {})
        .fromSuggestions([
          _suggestion('addNode', {
            'primitive': 'stringInput',
            'script': 'x = 1',
          }),
          _suggestion('configureNode', {
            'nodeRef': 'a',
            'fields': <String, Object?>{},
          }),
        ], cubit);

    expect(actions, hasLength(1));
    await cubit.close();
  });

  test('der Cursor tippt in das Feld und wird danach ausgeblendet', () async {
    final cubit = TaskBuilderCubit(
      repository: _InMemoryTaskRepository(_emptyTask),
    );
    await cubit.load(_emptyTask);
    final cursor = _RecordingCursor();
    final actions = TaskBuilderAgentCommandFactory(waitForFrame: () async {})
        .fromSuggestions([
          _suggestion('addNode', {
            'primitive': 'stringInput',
            'value': 'Hallo',
          }),
        ], cubit);

    await const AssistantPlanExecutor(
      stepDelay: Duration.zero,
    ).execute(actions, cursor: cursor);

    expect(cursor.events.last, 'hide');
    expect(
      cursor.events.where((e) => e.startsWith('type field:')),
      hasLength(1),
    );
    await cubit.close();
  });
}
