import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';

void main() {
  test('bietet nur Outputs und Script-Variablen aus Vorgängerpfad an', () {
    final graph = WorkflowGraph(
      nodes: [
        _node('eingabe'),
        _scriptNode(),
        _node('ziel'),
        _node('nachfolger'),
        _node('isoliert'),
      ],
      edges: [
        _edge('eingabe', 'script'),
        _edge('script', 'ziel'),
        _edge('ziel', 'nachfolger'),
      ],
    );

    final expressions = templateExpressionSuggestions(
      graph: graph,
      targetNodeId: const NodeId('ziel'),
    );

    expect(expressions.map((suggestion) => suggestion.expression), [
      '{{eingabe}}',
      '{{script}}',
      '{{kunde}}',
      '{{anzahl}}',
    ]);
  });
}

WorkflowNode _node(String id) => WorkflowNode(
  id: NodeId(id),
  title: id,
  description: '',
  outputName: id,
  config: const StringInputNodeConfig(value: ''),
);

WorkflowNode _scriptNode() => const WorkflowNode(
  id: NodeId('script'),
  title: 'Berechnung',
  description: '',
  outputName: 'script',
  config: ScriptNodeConfig(script: 'kunde = input\nanzahl = 2\noutput = kunde'),
);

WorkflowEdge _edge(String from, String to) =>
    WorkflowEdge(from: NodeId(from), to: NodeId(to));
