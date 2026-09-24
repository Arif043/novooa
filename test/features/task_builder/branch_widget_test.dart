import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';

void main() {
  testWidgets('rendert Branch-Nodes mit linken Drag-Streifen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BranchWidget(
            branch: _branch,
            conditionalNodeId: const NodeId('node.conditional'),
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.byType(NodeGraph), findsOneWidget);
    expect(
      find.byKey(const ValueKey('node-drag-strip-node.1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('node-drag-strip-node.2')),
      findsOneWidget,
    );
  });
}

const _branch = ConditionalBranch(
  id: 'branch.yes',
  label: 'Ja',
  graph: WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.1'),
        title: 'Eingabe eins',
        description: '',
        outputName: 'eingabe_eins',
        config: StringInputNodeConfig(value: ''),
      ),
      WorkflowNode(
        id: NodeId('node.2'),
        title: 'Eingabe zwei',
        description: '',
        outputName: 'eingabe_zwei',
        config: StringInputNodeConfig(value: ''),
      ),
    ],
    edges: [],
  ),
);
