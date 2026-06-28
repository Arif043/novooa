import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/run_task_definition_request_model.dart';

void main() {
  test('serialisiert TaskDefinition fuer runTaskDefinitionFlow', () {
    final json = RunTaskDefinitionRequestModel(
      taskDefinition: _task(),
      context: 'Kontext',
    ).toJson();

    final task = json['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final firstNode = nodes.first as Map<String, Object?>;
    final config = firstNode['config'] as Map<String, Object?>;

    expect(json['context'], 'Kontext');
    expect(task['id'], 'task.1');
    expect(firstNode['primitive'], 'prompt');
    expect(config['primitive'], 'prompt');
    expect(config['outputType'], 'decision');
    expect(task['edges'], isA<List<Object?>>());
  });
}

Task _task() {
  return const Task(
    id: 'task.1',
    title: 'Task',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.1'),
    nodes: [
      WorkflowNode(
        id: NodeId('node.1'),
        title: 'Prompt',
        description: 'Beschreibung',
        config: PromptNodeConfig(
          instruction: 'Entscheide.',
          outputType: PromptOutputType.decision,
          firstChoice: 'Ja',
          secondChoice: 'Nein',
        ),
      ),
    ],
    edges: [WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.1'))],
  );
}
