import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/domain/usecases/track_task_execution.dart';
import 'package:syscat2/features/activity/infrastructure/repositories/in_memory_task_activity_repository.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/infrastructure/datasources/mock_local_genkit_task_client.dart';
import 'package:syscat2/features/task_builder/infrastructure/repositories/local_genkit_task_runner_repository.dart';

void main() {
  test(
    'ExecuteTaskDefinition fuehrt Draft ueber lokalen Genkit-Mock aus',
    () async {
      const usecase = ExecuteTask(
        LocalGenkitTaskRunnerRepository(MockLocalGenkitTaskClient()),
      );

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
    },
  );

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
        const LocalGenkitTaskRunnerRepository(MockLocalGenkitTaskClient()),
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

Task _promptTask() {
  return const Task(
    id: 'task.1',
    title: 'Lokaler Test',
    objective: 'Genkit lokal testen',
    selectedNodeId: NodeId('node.1'),
    nodes: [
      WorkflowNode(
        id: NodeId('node.1'),
        title: 'Prompt',
        description: 'Beschreibung',
        config: PromptNodeConfig(
          instruction: 'Schreibe eine Antwort.',
          outputType: PromptOutputType.text,
          firstChoice: '',
          secondChoice: '',
        ),
      ),
    ],
    edges: [],
  );
}
