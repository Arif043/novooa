import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_chips.dart';

void main() {
  testWidgets('zeigt die Such- und Speicheroutputs für Datensätze', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              NodeOutputChips(node: _lookupNode()),
              NodeOutputChips(node: _saveNode()),
            ],
          ),
        ),
      ),
    );

    expect(find.text('found'), findsOneWidget);
    expect(find.text('record'), findsOneWidget);
    expect(find.text('created'), findsOneWidget);
    expect(find.text('count'), findsOneWidget);
    expect(find.text('records'), findsOneWidget);
  });
}

WorkflowNode _lookupNode() {
  return WorkflowNode(
    id: const NodeId('lookup'),
    title: 'Datensatz suchen',
    description: '',
    config: DocumentLookupNodeConfig.initial(),
  );
}

WorkflowNode _saveNode() {
  return WorkflowNode(
    id: const NodeId('save'),
    title: 'Datensatz speichern',
    description: '',
    config: SaveDocumentNodeConfig.initial(),
  );
}
