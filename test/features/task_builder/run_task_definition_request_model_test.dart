import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
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

  test('serialisiert Texteingabe fuer runTaskDefinitionFlow', () {
    final json = RunTaskDefinitionRequestModel(
      taskDefinition: _stringInputTask(),
      context: '',
    ).toJson();

    final task = json['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final input = nodes.first as Map<String, Object?>;
    final config = input['config'] as Map<String, Object?>;

    expect(input['primitive'], 'stringInput');
    expect(config['primitive'], 'stringInput');
    expect(config['value'], 'Manueller Entwurf');
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
    final graph = firstBranch['graph'] as Map<String, Object?>;
    final branchNodes = graph['nodes'] as List<Object?>;
    expect(firstBranch['id'], 'branch.yes');
    expect(firstBranch['label'], 'Ja');
    expect(branchNodes, hasLength(2));
  });

  test('serialisiert iterative Verfeinerung ohne internen Graph', () {
    final json = RunTaskDefinitionRequestModel(
      taskDefinition: _iterativeRefinementTask(),
      context: 'Entwurf',
    ).toJson();

    final task = json['taskDefinition'] as Map<String, Object?>;
    final nodes = task['nodes'] as List<Object?>;
    final refinement = nodes.first as Map<String, Object?>;
    final config = refinement['config'] as Map<String, Object?>;

    expect(refinement['primitive'], 'iterativeRefinement');
    expect(config['primitive'], 'iterativeRefinement');
    expect(config['critiquePrompt'], 'Pruefe auf Klarheit.');
    expect(config['maxIterations'], 3);
    expect(config.containsKey('graph'), isFalse);
  });
}

Task _task() {
  return const Task(
    id: 'task.1',
    title: 'Task',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.1'),
    graph: WorkflowGraph(
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
    ),
  );
}

Task _stringInputTask() {
  return const Task(
    id: 'task.input',
    title: 'Task',
    objective: 'Ziel',
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

Task _conditionalTask() {
  return Task(
    id: 'task.2',
    title: 'Task',
    objective: 'Ziel',
    selectedNodeId: NodeId('node.2'),
    graph: WorkflowGraph(
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
                graph: WorkflowGraph(
                  nodes: [
                    WorkflowNode(
                      id: NodeId('node.3'),
                      title: 'Prompt',
                      description: 'Beschreibung',
                      config: PromptNodeConfig.initial(),
                    ),
                    WorkflowNode(
                      id: NodeId('node.4'),
                      title: 'Prompt',
                      description: 'Beschreibung',
                      config: PromptNodeConfig.initial(),
                    ),
                  ],
                  edges: [
                    WorkflowEdge(from: NodeId('node.3'), to: NodeId('node.4')),
                  ],
                ),
              ),
              ConditionalBranch(
                id: 'branch.no',
                label: 'Nein',
                graph: WorkflowGraph(
                  nodes: [
                    WorkflowNode(
                      id: NodeId('node.5'),
                      title: 'Prompt',
                      description: 'Beschreibung',
                      config: PromptNodeConfig.initial(),
                    ),
                  ],
                  edges: [],
                ),
              ),
              ConditionalBranch(
                id: 'branch.maybe',
                label: 'Vielleicht',
                graph: WorkflowGraph(nodes: [], edges: []),
              ),
            ],
          ),
        ),
      ],
      edges: [WorkflowEdge(from: NodeId('node.2'), to: NodeId('node.2'))],
    ),
  );
}

Task _iterativeRefinementTask() {
  return Task(
    id: 'task.3',
    title: 'Task',
    objective: 'Ziel',
    selectedNodeId: const NodeId('node.6'),
    graph: WorkflowGraph(
      nodes: [
        WorkflowNode(
          id: const NodeId('node.6'),
          title: 'Iterative Verfeinerung',
          description: 'Beschreibung',
          config: IterativeRefinementNodeConfig(
            critiquePrompt: 'Pruefe auf Klarheit.',
            maxIterations: 3,
          ),
        ),
      ],
      edges: const [],
    ),
  );
}
