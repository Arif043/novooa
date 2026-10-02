import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

// Deckt einen Bug ab: `removeNode` entfernte bisher nur den Knoten samt
// seinen Kanten, ohne Vorgänger und Nachfolger neu zu verbinden — ein
// Knoten in der Mitte einer Kette zu entfernen zerlegte den Graphen in zwei
// unverbundene Komponenten (Teilgraphen), statt die Kette zu schließen.
void main() {
  const a = NodeId('a');
  const b = NodeId('b');
  const c = NodeId('c');

  WorkflowNode node(NodeId id) => WorkflowNode(
    id: id,
    title: id.value,
    description: '',
    config: const StringInputNodeConfig(value: ''),
  );

  test('entfernt man den mittleren Knoten einer Kette, wird der Vorgänger '
      'direkt mit dem Nachfolger verbunden — keine zwei Teilgraphen', () {
    final graph = WorkflowGraph(
      nodes: [node(a), node(b), node(c)],
      edges: const [
        WorkflowEdge(from: a, to: b),
        WorkflowEdge(from: b, to: c),
      ],
    );

    final result = graph.removeNode(b);

    expect(result.nodes.map((n) => n.id), [a, c]);
    expect(result.edges, [const WorkflowEdge(from: a, to: c)]);
  });

  test(
    'entfernt man den Kopf einer Kette, bleibt der Rest unverändert verbunden',
    () {
      final graph = WorkflowGraph(
        nodes: [node(a), node(b), node(c)],
        edges: const [
          WorkflowEdge(from: a, to: b),
          WorkflowEdge(from: b, to: c),
        ],
      );

      final result = graph.removeNode(a);

      expect(result.nodes.map((n) => n.id), [b, c]);
      expect(result.edges, [const WorkflowEdge(from: b, to: c)]);
    },
  );

  test(
    'entfernt man das Ende einer Kette, bleibt der Rest unverändert verbunden',
    () {
      final graph = WorkflowGraph(
        nodes: [node(a), node(b), node(c)],
        edges: const [
          WorkflowEdge(from: a, to: b),
          WorkflowEdge(from: b, to: c),
        ],
      );

      final result = graph.removeNode(c);

      expect(result.nodes.map((n) => n.id), [a, b]);
      expect(result.edges, [const WorkflowEdge(from: a, to: b)]);
    },
  );

  test('erzeugt keine doppelte Kante, wenn Vorgänger und Nachfolger bereits '
      'direkt verbunden sind', () {
    final graph = WorkflowGraph(
      nodes: [node(a), node(b), node(c)],
      edges: const [
        WorkflowEdge(from: a, to: b),
        WorkflowEdge(from: b, to: c),
        WorkflowEdge(from: a, to: c),
      ],
    );

    final result = graph.removeNode(b);

    expect(result.edges, [const WorkflowEdge(from: a, to: c)]);
  });

  test('verbindet bei mehreren Vorgängern/Nachfolgern jeden Vorgänger mit '
      'jedem Nachfolger (Kreuzprodukt)', () {
    const d = NodeId('d');
    final graph = WorkflowGraph(
      nodes: [node(a), node(b), node(c), node(d)],
      edges: const [
        WorkflowEdge(from: a, to: c),
        WorkflowEdge(from: b, to: c),
        WorkflowEdge(from: c, to: d),
      ],
    );

    final result = graph.removeNode(c);

    expect(result.nodes.map((n) => n.id), [a, b, d]);
    expect(result.edges.toSet(), {
      const WorkflowEdge(from: a, to: d),
      const WorkflowEdge(from: b, to: d),
    });
  });

  test('entfernt einen isolierten Knoten ohne Kanten unverändert', () {
    final graph = WorkflowGraph(nodes: [node(a)], edges: const []);

    final result = graph.removeNode(a);

    expect(result.nodes, isEmpty);
    expect(result.edges, isEmpty);
  });
}
