import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/prompt_node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_definition.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task_definition.dart';
import 'package:syscat2/features/task_builder/infrastructure/datasources/mock_local_genkit_task_client.dart';
import 'package:syscat2/features/task_builder/infrastructure/repositories/local_genkit_task_runner_repository.dart';

void main() {
  test(
    'ExecuteTaskDefinition fuehrt Draft ueber lokalen Genkit-Mock aus',
    () async {
      const usecase = ExecuteTaskDefinition(
        LocalGenkitTaskRunnerRepository(MockLocalGenkitTaskClient()),
      );

      final taskExecutionOrFailure = await usecase(
        ExecuteTaskDefinitionParams(
          taskDefinition: _promptTask(),
          context: 'Lokaler Testkontext',
        ),
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
}

TaskDefinition _promptTask() {
  return const TaskDefinition(
    id: 'task.1',
    title: 'Lokaler Test',
    objective: 'Genkit lokal testen',
    selectedNodeId: NodeId('node.1'),
    nodes: [
      WorkflowNode(
        id: NodeId('node.1'),
        primitive: WorkflowPrimitive.prompt,
        title: 'Prompt',
        description: 'Beschreibung',
        promptConfig: PromptNodeConfig(
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
