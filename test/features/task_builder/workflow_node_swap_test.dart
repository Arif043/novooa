import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_edge.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/services/workflow_node_swap.dart';

// Hauptplan: start → bedingung → ende. Zweig „ja“: a → b, Zweig „nein“: c.
const _start = NodeId('start');
const _condition = NodeId('bedingung');
const _end = NodeId('ende');
const _a = NodeId('a');
const _b = NodeId('b');
const _c = NodeId('c');

void main() {
  test('tauscht einen Baustein im Zweig mit einem im Hauptplan', () {
    final swapped = WorkflowNodeSwap(_plan()).swap(_a, _end);

    expect(_ids(swapped), ['start', 'bedingung', 'a']);
    expect(_ids(_branch(swapped, 'ja')), ['ende', 'b']);
    expect(
      _branch(swapped, 'ja').edges.single,
      const WorkflowEdge(from: _end, to: _b),
    );
    expect(swapped.edges.last, const WorkflowEdge(from: _condition, to: _a));
  });

  test('tauscht Bausteine aus verschiedenen Zweigen', () {
    final swapped = WorkflowNodeSwap(_plan()).swap(_b, _c);

    expect(_ids(_branch(swapped, 'ja')), ['a', 'c']);
    expect(_ids(_branch(swapped, 'nein')), ['b']);
    expect(
      _branch(swapped, 'ja').edges.single,
      const WorkflowEdge(from: _a, to: _c),
    );
  });

  test('im selben Graphen tauschen Bausteine Platz und Kanten', () {
    final swapped = WorkflowNodeSwap(_plan()).swap(_start, _end);

    expect(_ids(swapped), ['ende', 'bedingung', 'start']);
    expect(swapped.edges.first, const WorkflowEdge(from: _end, to: _condition));
  });

  test('eine Bedingung kann nicht in ihren eigenen Zweig wandern', () {
    final swap = WorkflowNodeSwap(_plan());

    expect(swap.canSwap(_condition, _a), isFalse);
    expect(swap.canSwap(_c, _condition), isFalse);
    expect(swap.swap(_condition, _a), _plan());
  });

  test('ein Baustein tauscht auch mit dem Unterplan einer Schleife', () {
    final plan = WorkflowGraph(
      nodes: [
        _node('start'),
        _loop([_node('innen')]),
      ],
      edges: const [WorkflowEdge(from: _start, to: NodeId('schleife'))],
    );

    final swapped = WorkflowNodeSwap(plan).swap(_start, const NodeId('innen'));

    expect(_ids(swapped), ['innen', 'schleife']);
    final loop = swapped.nodes.last.config as ForEachNodeConfig;
    expect(_ids(loop.graph), ['start']);
  });
}

WorkflowGraph _plan() => WorkflowGraph(
  nodes: [
    _node('start'),
    WorkflowNode(
      id: _condition,
      title: 'Bedingung',
      description: '',
      config: ConditionalNodeConfig(
        branches: [
          ConditionalBranch(
            id: 'ja',
            label: 'Ja',
            graph: WorkflowGraph(
              nodes: [_node('a'), _node('b')],
              edges: const [WorkflowEdge(from: _a, to: _b)],
            ),
          ),
          ConditionalBranch(
            id: 'nein',
            label: 'Nein',
            graph: WorkflowGraph(nodes: [_node('c')], edges: const []),
          ),
        ],
      ),
    ),
    _node('ende'),
  ],
  edges: const [
    WorkflowEdge(from: _start, to: _condition),
    WorkflowEdge(from: _condition, to: _end),
  ],
);

WorkflowNode _loop(List<WorkflowNode> nodes) => WorkflowNode(
  id: const NodeId('schleife'),
  title: 'Schleife',
  description: '',
  config: ForEachNodeConfig(
    itemsPointer: '',
    graph: WorkflowGraph(nodes: nodes, edges: const []),
  ),
);

WorkflowNode _node(String id) => WorkflowNode(
  id: NodeId(id),
  title: id,
  description: '',
  config: const StringInputNodeConfig(value: ''),
);

WorkflowGraph _branch(WorkflowGraph plan, String branchId) {
  final config = plan.nodes[1].config as ConditionalNodeConfig;
  return config.branches.firstWhere((branch) => branch.id == branchId).graph;
}

List<String> _ids(WorkflowGraph graph) =>
    graph.nodes.map((node) => node.id.value).toList();
