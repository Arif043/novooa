import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/usecases/track_task_execution.dart';
import 'package:syscat2/features/activity/infrastructure/repositories/in_memory_task_activity_repository.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/run_task_definition_request_model.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_execution_result_model.dart';

void main() {
  test('ExecuteTaskDefinition fuehrt Draft ueber Datasource aus', () async {
    final usecase = ExecuteTask(FakeTaskRepository(FakeTaskRunnerDatasource()));

    final taskExecutionOrFailure = await usecase(
      ExecuteTaskParams(task: _promptTask(), context: 'Lokaler Testkontext'),
    );

    taskExecutionOrFailure.when((taskExecution) {
      expect(taskExecution.taskId, 'task.1');
      expect(taskExecution.finalOutput, contains('Schreibe eine Antwort'));
      expect(
        taskExecution.nodeResults.single.status,
        NodeExecutionStatus.executed,
      );
    }, (failure) => fail(failure.message));
  });

  test('ExecuteTaskDefinition gibt Texteingabe als Output weiter', () async {
    final usecase = ExecuteTask(FakeTaskRepository(FakeTaskRunnerDatasource()));

    final taskExecutionOrFailure = await usecase(
      ExecuteTaskParams(task: _stringInputTask()),
    );

    taskExecutionOrFailure.when((taskExecution) {
      expect(taskExecution.finalOutput, 'Manueller Entwurf');
      expect(
        taskExecution.nodeResults.single.status,
        NodeExecutionStatus.executed,
      );
      expect(taskExecution.nodeResults.single.output, 'Manueller Entwurf');
    }, (failure) => fail(failure.message));
  });

  test(
    'ExecuteTaskDefinition trackt Task- und Baustein-Aktivitaeten',
    () async {
      var nextId = 0;
      final activityRepository = InMemoryTaskActivityRepository();
      final tracker = TrackTaskExecution(
        activityRepository,
        clock: () => DateTime.utc(2026),
        idFactory: () => UniqueId('activity.${nextId++}'),
      );
      final usecase = ExecuteTask(
        FakeTaskRepository(FakeTaskRunnerDatasource()),
        tracker: tracker,
      );

      await usecase(
        ExecuteTaskParams(task: _promptTask(), context: 'Lokaler Testkontext'),
      );

      final activities = (await activityRepository.listRecent()).reversed
          .toList();
      expect(activities.length, 3);
      expect(activities.first.status, TaskActivityStatus.started);
      expect(activities[1].target, TaskActivityTarget.node);
      expect(activities[1].status, TaskActivityStatus.succeeded);
      expect(activities.last.output, contains('Schreibe eine Antwort'));
      expect(activities.map((activity) => activity.runId).toSet().length, 1);
    },
  );
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this._datasource);

  final FakeTaskRunnerDatasource _datasource;

  @override
  Future<List<Task>> loadTasks() async => const [];

  @override
  Future<void> saveTask(Task task) async {
    _datasource.saveTask(task);
  }

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    await saveTask(task);
    final response = await _datasource.runTaskDefinition(
      RunTaskDefinitionRequestModel(taskId: task.id, context: context).toJson(),
    );
    return Success(TaskExecutionResultModel.fromJson(response).toDomain());
  }
}

class FakeTaskRunnerDatasource implements TaskRunnerDatasource {
  final Map<String, Task> _tasks = {};

  void saveTask(Task task) {
    _tasks[task.id] = task;
  }

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    expect(request.containsKey('taskDefinition'), isFalse);
    final taskId = request['taskId'] as String;
    final task = _tasks[taskId]!;
    final nodes = task.graph.nodes;
    final nodeResults = nodes.map(_nodeResult).toList(growable: false);
    return {
      'taskId': task.id,
      'finalOutput': _finalOutput(nodeResults),
      'nodeResults': nodeResults,
    };
  }

  Map<String, Object?> _nodeResult(WorkflowNode node) {
    final primitive = _primitiveName(node.config);
    final output = switch (primitive) {
      'stringInput' => _stringInputOutput(node),
      'script' => _scriptOutput(node),
      'prompt' => _promptOutput(node),
      _ => 'Mock: $primitive wurde übersprungen.',
    };
    final executed = {'stringInput', 'script', 'prompt'}.contains(primitive);
    return {
      'nodeId': node.id.value,
      'primitive': primitive,
      'status': executed ? 'executed' : 'skipped',
      'output': output,
      'message': executed ? null : 'Mock ohne Executor.',
    };
  }

  String _primitiveName(NodeConfig config) {
    return switch (config.primitive) {
      WorkflowPrimitive.conditional => 'conditionalFlow',
      _ => config.primitive.name,
    };
  }

  String _stringInputOutput(WorkflowNode node) {
    final config = node.config;
    if (config is StringInputNodeConfig) return config.value;
    return '';
  }

  String _scriptOutput(WorkflowNode node) {
    final config = node.config;
    if (config is ScriptNodeConfig) return config.script;
    return '';
  }

  String _promptOutput(WorkflowNode node) {
    final config = node.config;
    final instruction = config is PromptNodeConfig ? config.instruction : '';
    if (instruction.trim().isNotEmpty) return 'Mock-Antwort: $instruction';
    return 'Mock-Antwort: ${node.title}';
  }

  String _finalOutput(List<Map<String, Object?>> nodeResults) {
    for (final result in nodeResults.reversed) {
      final output = result['output'] as String? ?? '';
      if (output.trim().isNotEmpty) return output;
    }
    return '';
  }
}

Task _promptTask() {
  return const Task(
    id: 'task.1',
    title: 'Lokaler Test',
    objective: 'Genkit lokal testen',
    selectedNodeId: NodeId('node.1'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.1'),
          title: 'Prompt',
          description: 'Beschreibung',
          config: PromptNodeConfig(
            instruction: 'Schreibe eine Antwort.',
            outputType: PromptOutputType.text,
            choices: [],
          ),
        ),
      ],
      edges: [],
    ),
  );
}

Task _stringInputTask() {
  return const Task(
    id: 'task.input',
    title: 'Lokaler Test',
    objective: 'Genkit lokal testen',
    selectedNodeId: NodeId('node.input'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: NodeId('node.input'),
          title: 'Texteingabe',
          description: 'Beschreibung',
          config: StringInputNodeConfig(value: 'Manueller Entwurf'),
        ),
      ],
      edges: [],
    ),
  );
}
