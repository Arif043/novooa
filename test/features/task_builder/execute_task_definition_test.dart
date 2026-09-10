import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_failure.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_run_start.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/run_task_definition_request_model.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/task_run_start_model.dart';

void main() {
  test('ExecuteTask startet eine Aufgabe im Hintergrund', () async {
    final usecase = ExecuteTask(FakeTaskRepository(FakeTaskRunnerDatasource()));

    final taskRunOrFailure = await usecase(
      ExecuteTaskParams(task: _promptTask(), context: 'Kontext'),
    );

    taskRunOrFailure.when((run) {
      expect(run.taskId, 'task.1');
      expect(run.runId.value, 'run.task.1');
    }, (failure) => fail(failure.message));
  });
}

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this._datasource);

  final FakeTaskRunnerDatasource _datasource;

  @override
  Stream<List<Task>> watchTasks() => Stream.value(const []);

  @override
  Future<void> saveTask(Task task) async {
    _datasource.saveTask(task);
  }

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<Result<TaskRunStart, TaskRunFailure>> execute({
    required Task task,
    String context = '',
  }) async {
    await saveTask(task);
    final response = await _datasource.runTaskDefinition(
      RunTaskDefinitionRequestModel(taskId: task.id, context: context).toJson(),
    );
    return Success(TaskRunStartModel.fromJson(response).toDomain());
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
    expect(_tasks.containsKey(taskId), isTrue);
    return {'runId': 'run.$taskId', 'taskId': taskId, 'status': 'queued'};
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
