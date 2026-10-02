import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_predecessor.dart';

void main() {
  group('directPredecessorOf', () {
    test('findet den direkten Vorgänger im Wurzel-Graphen', () {
      const promptId = NodeId('prompt.1');
      const conditionalId = NodeId('conditional.1');
      final graph = WorkflowGraph(
        nodes: [_promptNode(promptId), _conditionalNode(conditionalId)],
        edges: [WorkflowEdge(from: promptId, to: conditionalId)],
      );

      final predecessor = directPredecessorOf(graph, conditionalId);

      expect(predecessor?.id, promptId);
    });

    test('liefert null ohne Vorgänger', () {
      const conditionalId = NodeId('conditional.1');
      final graph = WorkflowGraph(
        nodes: [_conditionalNode(conditionalId)],
        edges: const [],
      );

      expect(directPredecessorOf(graph, conditionalId), isNull);
    });

    test('liefert null bei mehreren eingehenden Kanten (mehrdeutig)', () {
      const promptId = NodeId('prompt.1');
      const otherId = NodeId('other.1');
      const conditionalId = NodeId('conditional.1');
      final graph = WorkflowGraph(
        nodes: [
          _promptNode(promptId),
          _promptNode(otherId),
          _conditionalNode(conditionalId),
        ],
        edges: [
          WorkflowEdge(from: promptId, to: conditionalId),
          WorkflowEdge(from: otherId, to: conditionalId),
        ],
      );

      expect(directPredecessorOf(graph, conditionalId), isNull);
    });

    test('findet den Vorgänger innerhalb eines Verzweigungs-Zweigs', () {
      const promptId = NodeId('prompt.1');
      const conditionalId = NodeId('conditional.2');
      final nestedGraph = WorkflowGraph(
        nodes: [_promptNode(promptId), _conditionalNode(conditionalId)],
        edges: [WorkflowEdge(from: promptId, to: conditionalId)],
      );
      final rootGraph = WorkflowGraph(
        nodes: [
          WorkflowNode(
            id: const NodeId('root.conditional'),
            title: '',
            description: '',
            config: ConditionalNodeConfig(
              branches: [
                ConditionalBranch(id: 'b1', label: 'Ja', graph: nestedGraph),
              ],
            ),
          ),
        ],
        edges: const [],
      );

      final predecessor = directPredecessorOf(rootGraph, conditionalId);

      expect(predecessor?.id, promptId);
    });

    test(
      'findet den Vorgänger innerhalb eines "Für jedes Element"-Graphen',
      () {
        const promptId = NodeId('prompt.1');
        const conditionalId = NodeId('conditional.2');
        final nestedGraph = WorkflowGraph(
          nodes: [_promptNode(promptId), _conditionalNode(conditionalId)],
          edges: [WorkflowEdge(from: promptId, to: conditionalId)],
        );
        final rootGraph = WorkflowGraph(
          nodes: [
            WorkflowNode(
              id: const NodeId('root.foreach'),
              title: '',
              description: '',
              config: ForEachNodeConfig(itemsPointer: '', graph: nestedGraph),
            ),
          ],
          edges: const [],
        );

        final predecessor = directPredecessorOf(rootGraph, conditionalId);

        expect(predecessor?.id, promptId);
      },
    );
  });
}

WorkflowNode _promptNode(NodeId id) {
  return WorkflowNode(
    id: id,
    title: 'Prompt',
    description: '',
    outputName: 'entscheidung',
    config: const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.decision,
      choices: ['Ja', 'Nein'],
    ),
  );
}

WorkflowNode _conditionalNode(NodeId id) {
  return WorkflowNode(
    id: id,
    title: 'Bedingter Ablauf',
    description: '',
    config: const ConditionalNodeConfig(branches: []),
  );
}
