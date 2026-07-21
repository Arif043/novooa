import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_position_transition.dart';

void main() {
  testWidgets('bewegt einen Baustein sichtbar zur neuen Position', (
    tester,
  ) async {
    final hostKey = GlobalKey<_TransitionHostState>();
    await tester.pumpWidget(_TransitionHost(key: hostKey));

    hostKey.currentState!.animateFrom(100);
    await tester.pump();
    expect(_verticalPosition(tester), closeTo(100, 0.1));

    await tester.pump(const Duration(milliseconds: 110));
    expect(_verticalPosition(tester), inExclusiveRange(0, 100));

    await tester.pump(const Duration(milliseconds: 110));
    expect(_verticalPosition(tester), closeTo(0, 0.1));
  });

  testWidgets('animiert vertauschte Bausteine zwischen ihren Positionen', (
    tester,
  ) async {
    final hostKey = GlobalKey<_NodeGraphHostState>();
    await tester.pumpWidget(_NodeGraphHost(key: hostKey));
    final firstStart = _nodeTop(tester, 'node.1');
    final secondStart = _nodeTop(tester, 'node.2');

    hostKey.currentState!.swap();
    await tester.pump();
    expect(
      _nodeOffset(tester, 'node.1'),
      closeTo(firstStart - secondStart, 0.1),
    );
    expect(
      _nodeOffset(tester, 'node.2'),
      closeTo(secondStart - firstStart, 0.1),
    );
    expect(_nodeTop(tester, 'node.1'), closeTo(firstStart, 0.1));
    expect(_nodeTop(tester, 'node.2'), closeTo(secondStart, 0.1));

    await tester.pump(const Duration(milliseconds: 110));
    expect(
      _nodeTop(tester, 'node.1'),
      inExclusiveRange(firstStart, secondStart),
    );

    await tester.pump(const Duration(milliseconds: 110));
    expect(_nodeTop(tester, 'node.1'), closeTo(secondStart, 0.1));
    expect(_nodeTop(tester, 'node.2'), closeTo(firstStart, 0.1));
  });
}

double _verticalPosition(WidgetTester tester) {
  return tester.getTopLeft(find.byKey(const ValueKey('node'))).dy;
}

double _nodeTop(WidgetTester tester, String nodeId) {
  return tester.getTopLeft(find.byKey(ValueKey('node-content-$nodeId'))).dy;
}

double _nodeOffset(WidgetTester tester, String nodeId) {
  final transition = tester.widget<NodePositionTransition>(
    find.byKey(ValueKey(NodeId(nodeId))),
  );
  return transition.offsetY;
}

class _TransitionHost extends StatefulWidget {
  const _TransitionHost({super.key});

  @override
  State<_TransitionHost> createState() => _TransitionHostState();
}

class _TransitionHostState extends State<_TransitionHost> {
  double _offset = 0;

  void animateFrom(double offset) => setState(() => _offset = offset);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: NodePositionTransition(
          offsetY: _offset,
          child: const SizedBox(key: ValueKey('node'), width: 100, height: 100),
        ),
      ),
    );
  }
}

class _NodeGraphHost extends StatefulWidget {
  const _NodeGraphHost({super.key});

  @override
  State<_NodeGraphHost> createState() => _NodeGraphHostState();
}

class _NodeGraphHostState extends State<_NodeGraphHost> {
  late List<WorkflowNode> _nodes = [_node('node.1'), _node('node.2')];

  void swap() => setState(() => _nodes = _nodes.reversed.toList());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(body: NodeGraph(nodes: _nodes)),
    );
  }
}

WorkflowNode _node(String id) {
  return WorkflowNode(
    id: NodeId(id),
    title: id,
    description: '',
    referenceName: id,
    config: StringInputNodeConfig.initial(),
  );
}
