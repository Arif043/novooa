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
    expect(config['choices'], ['Ja', 'Nein', 'Vielleicht']);
    expect(task['edges'], isA<List<Object?>>());
  });

  test('serialisiert Verzweigungsfaelle fuer runTaskDefinitionFlow', () {
    final json = RunTaskDefinitionRequestModel(
      taskDefinition: _conditionalTask(),
      context: 'Ja',
    ).toJson();

    final task = json['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final branch = nodes.first as Map<String, Object?>;
    final config = branch['config'] as Map<String, Object?>;

    expect(branch['primitive'], 'conditionalFlow');
    expect(config['primitive'], 'conditionalFlow');
    expect(config['choices'], ['Ja', 'Nein', 'Vielleicht']);
    final branches = config['branches'] as List<Object?>;
    final firstBranch = branches.first as Map<String, Object?>;
    expect(firstBranch['id'], 'branch.yes');
    expect(firstBranch['label'], 'Ja');
    expect(firstBranch['nodeIds'], ['node.3', 'node.4']);
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
          choices: ['Ja', 'Nein', 'Vielleicht'],
        ),
      ),
    ],
    edges: [WorkflowEdge(from: NodeId('node.1'), to: NodeId('node.1'))],
  );
}

Task _conditionalTask() {
  return const Task(
    id: 'task.2',
    title: 'Task',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.2'),
    nodes: [
      WorkflowNode(
        id: NodeId('node.2'),
        title: 'Verzweigung',
        description: 'Beschreibung',
        config: ConditionalNodeConfig(
          branches: [
            ConditionalBranch(
              id: 'branch.yes',
              label: 'Ja',
              nodeIds: [NodeId('node.3'), NodeId('node.4')],
            ),
            ConditionalBranch(
              id: 'branch.no',
              label: 'Nein',
              nodeIds: [NodeId('node.5')],
            ),
            ConditionalBranch(
              id: 'branch.maybe',
              label: 'Vielleicht',
              nodeIds: [],
            ),
          ],
        ),
      ),
    ],
    edges: [WorkflowEdge(from: NodeId('node.2'), to: NodeId('node.2'))],
  );
}
