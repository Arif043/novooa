import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/condition_value_sources.dart';

WorkflowNode node(String id) => WorkflowNode(
  id: NodeId(id),
  title: id,
  description: '',
  outputs: [WorkflowOutput.primary(id)],
  config: const StringInputNodeConfig(value: ''),
);
WorkflowEdge edge(String from, String to) =>
    WorkflowEdge(from: NodeId(from), to: NodeId(to));

void main() {
  test(
    'Nur verbundene Vorgänger, keine Nachfolger oder isolierten Bausteine',
    () {
      final graph = WorkflowGraph(
        nodes: [
          node('a'),
          node('b'),
          node('target'),
          node('later'),
          node('other'),
        ],
        edges: [edge('a', 'b'), edge('b', 'target'), edge('target', 'later')],
      );
      final sources = conditionValueSources(
        conditionSourceGraph(graph, const NodeId('target')),
      );
      expect(sources, {'{{a}}': 'a · a', '{{b}}': 'b · b'});
    },
  );

  test('Unterpfad erbt äußere Vorgänger, aber keine Geschwisterpfade', () {
    final branch = node('branch').copyWith(
      config: ConditionalNodeConfig(
        branches: [
          ConditionalBranch(
            id: 'yes',
            label: 'Ja',
            graph: WorkflowGraph(
              nodes: [node('local'), node('target')],
              edges: [edge('local', 'target')],
            ),
          ),
          ConditionalBranch(
            id: 'no',
            label: 'Nein',
            graph: WorkflowGraph(nodes: [node('sibling')], edges: []),
          ),
        ],
      ),
    );
    final graph = WorkflowGraph(
      nodes: [node('outer'), branch],
      edges: [edge('outer', 'branch')],
    );
    final sources = conditionValueSources(
      conditionSourceGraph(graph, const NodeId('target')),
    );
    expect(sources.keys, ['{{outer}}', '{{local}}']);
  });
}
