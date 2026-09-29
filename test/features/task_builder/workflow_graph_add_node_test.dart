import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';

// Deckt einen Bug ab: `addNode` fügte einen neuen Baustein bisher immer nur
// über eine zusätzliche, parallele Kante an — ein bereits verzweigter
// Baustein bekam dadurch bei jedem weiteren Einfügen einen zusätzlichen
// Zweig, statt den neuen Baustein als seinen einen direkten Nachfolger zu
// bekommen. `addNode` spleißt jetzt bestehende Nachfolger auf den neuen
// Baustein um.
void main() {
  const a = NodeId('a');
  const b = NodeId('b');
  const c = NodeId('c');
  const n = NodeId('n');

  WorkflowNode node(NodeId id) => WorkflowNode(
    id: id,
    title: id.value,
    description: '',
    config: const StringInputNodeConfig(value: ''),
  );

  test('fügt den ersten Knoten in einen leeren Graphen ohne Kante ein', () {
    final graph = WorkflowGraph.empty();

    final result = graph.addNode(node(a), a);

    expect(result.nodes.map((node) => node.id), [a]);
    expect(result.edges, isEmpty);
  });

  test(
    'fügt nach einem Blatt-Knoten (ohne Nachfolger) einfach eine neue Kante '
    'an',
    () {
      final graph = WorkflowGraph(nodes: [node(a)], edges: const []);

      final result = graph.addNode(node(b), a);

      expect(result.nodes.map((node) => node.id), [a, b]);
      expect(result.edges, [const WorkflowEdge(from: a, to: b)]);
    },
  );

  test(
    'spleißt einen bestehenden Nachfolger auf den neuen Knoten, statt einen '
    'zweiten parallelen Zweig anzulegen',
    () {
      final graph = WorkflowGraph(
        nodes: [node(a), node(b)],
        edges: const [WorkflowEdge(from: a, to: b)],
      );

      final result = graph.addNode(node(n), a);

      expect(result.nodes.map((node) => node.id), [a, b, n]);
      expect(result.edges.toSet(), {
        const WorkflowEdge(from: a, to: n),
        const WorkflowEdge(from: n, to: b),
      });
    },
  );

  test(
    'spleißt alle bestehenden Nachfolger auf den neuen Knoten, wenn der '
    'fokussierte Baustein bereits mehrfach verzweigt',
    () {
      final graph = WorkflowGraph(
        nodes: [node(a), node(b), node(c)],
        edges: const [
          WorkflowEdge(from: a, to: b),
          WorkflowEdge(from: a, to: c),
        ],
      );

      final result = graph.addNode(node(n), a);

      expect(result.nodes.map((node) => node.id), [a, b, c, n]);
      expect(result.edges.toSet(), {
        const WorkflowEdge(from: a, to: n),
        const WorkflowEdge(from: n, to: b),
        const WorkflowEdge(from: n, to: c),
      });
    },
  );

  test('erhält das Bedingungs-Label einer gespleißten Kante', () {
    final graph = WorkflowGraph(
      nodes: [node(a), node(b)],
      edges: const [
        WorkflowEdge(from: a, to: b, conditionLabel: 'Ja'),
      ],
    );

    final result = graph.addNode(node(n), a);

    expect(
      result.edges,
      containsAll(const [
        WorkflowEdge(from: n, to: b, conditionLabel: 'Ja'),
      ]),
    );
  });

  test('lässt einen unbeteiligten Teil des Graphen unangetastet', () {
    final graph = WorkflowGraph(
      nodes: [node(a), node(b), node(c)],
      edges: const [
        WorkflowEdge(from: a, to: b),
        WorkflowEdge(from: b, to: c),
      ],
    );

    final result = graph.addNode(node(n), a);

    expect(result.edges, contains(const WorkflowEdge(from: b, to: c)));
  });
}
