import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_comparison_row.dart';

Future<void> _pumpRow(WidgetTester tester, ComparisonOperator operator) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ComparisonRow(
            comparison: ComparisonCondition(
              left: 'true',
              operator: operator,
              right: '',
            ),
            graph: WorkflowGraph.empty(),
            onChanged: (_) {},
            onRemove: null,
            onGroup: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('„ist wahr“ braucht keinen Vergleichswert', (tester) async {
    await _pumpRow(tester, ComparisonOperator.isTrue);

    expect(find.text('ist wahr'), findsOneWidget);
    expect(find.text('Vergleichswert'), findsNothing);
  });

  testWidgets('„ist“ zeigt den Vergleichswert', (tester) async {
    await _pumpRow(tester, ComparisonOperator.equals);

    expect(find.text('Vergleichswert'), findsOneWidget);
  });
}
