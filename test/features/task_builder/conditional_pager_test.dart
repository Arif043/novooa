import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/conditional_pager.dart';

void main() {
  testWidgets('bleibt nach Branch-Mutation auf der Branch-Seite', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_conditionalNode()));
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fall:'), findsOneWidget);

    await tester.pumpWidget(
      _app(_conditionalNode(branchGraph: _promptGraph())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Fall:'), findsOneWidget);
    expect(find.text('Prompt'), findsOneWidget);
    expect(find.text('Wenn'), findsNothing);
  });
}

Widget _app(WorkflowNode node) {
  return MaterialApp(
    home: Scaffold(body: ConditionalPager(node: node)),
  );
}

WorkflowNode _conditionalNode({WorkflowGraph? branchGraph}) {
  return WorkflowNode(
    id: const NodeId('node.1'),
    title: 'Verzweigung',
    description: 'Beschreibung',
    config: ConditionalNodeConfig(
      branches: [
        ConditionalBranch(
          id: 'branch.yes',
          label: 'Ja',
          graph: branchGraph ?? WorkflowGraph.empty(),
        ),
      ],
    ),
  );
}

WorkflowGraph _promptGraph() {
  return const WorkflowGraph(
    nodes: [
      WorkflowNode(
        id: NodeId('node.2'),
        title: 'Prompt',
        description: 'Beschreibung',
        config: PromptNodeConfig(
          instruction: '',
          outputType: PromptOutputType.text,
          choices: ['', ''],
        ),
      ),
    ],
    edges: [],
  );
}
