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
    const usecase = ExecuteTask(FakeTaskRepository(FakeTaskRunnerDatasource()));

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
    const usecase = ExecuteTask(FakeTaskRepository(FakeTaskRunnerDatasource()));

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
        const FakeTaskRepository(FakeTaskRunnerDatasource()),
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
  const FakeTaskRepository(this._datasource);

  final TaskRunnerDatasource _datasource;

  @override
  Future<List<Task>> loadTasks() async => const [];

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<Result<TaskExecutionResult, TaskExecutionFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    final response = await _datasource.runTaskDefinition(
      RunTaskDefinitionRequestModel(
        taskDefinition: task,
        context: context,
      ).toJson(),
    );
    return Success(TaskExecutionResultModel.fromJson(response).toDomain());
  }
}

class FakeTaskRunnerDatasource implements TaskRunnerDatasource {
  const FakeTaskRunnerDatasource();

  @override
  Future<Map<String, Object?>> runTaskDefinition(
    Map<String, Object?> request,
  ) async {
    final task = request['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final nodeResults = nodes.map(_nodeResult).toList(growable: false);
    return {
      'taskId': task['id'] as String,
      'finalOutput': _finalOutput(nodeResults),
      'nodeResults': nodeResults,
    };
  }

  Map<String, Object?> _nodeResult(Object? rawNode) {
    final node = rawNode as Map<String, Object?>;
    final primitive = node['primitive'] as String;
    final output = switch (primitive) {
      'stringInput' => _stringInputOutput(node),
      'prompt' => _promptOutput(node),
      _ => 'Mock: $primitive wurde übersprungen.',
    };
    final executed = primitive == 'stringInput' || primitive == 'prompt';
    return {
      'nodeId': node['id'] as String,
      'primitive': primitive,
      'status': executed ? 'executed' : 'skipped',
      'output': output,
      'message': executed ? null : 'Mock ohne Executor.',
    };
  }

  String _stringInputOutput(Map<String, Object?> node) {
    final config = node['config'] as Map<String, Object?>?;
    return config?['value'] as String? ?? '';
  }

  String _promptOutput(Map<String, Object?> node) {
    final config = node['config'] as Map<String, Object?>?;
    final instruction = config?['instruction'] as String? ?? '';
    if (instruction.trim().isNotEmpty) return 'Mock-Antwort: $instruction';
    return 'Mock-Antwort: ${node['title']}';
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
