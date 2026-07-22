import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_chips.dart';

void main() {
  testWidgets('zeigt strukturierte Prompt-Felder als Output-Chips', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_structuredPromptNode()));

    expect(find.text('titel'), findsOneWidget);
    expect(find.text('zusammenfassung'), findsOneWidget);
    expect(find.text('text'), findsNothing);
    expect(find.text(''), findsNothing);
  });

  testWidgets('zeigt die strukturierten Datei-Outputs', (tester) async {
    await tester.pumpWidget(_host(_writeFileNode()));

    expect(find.text('fileId'), findsOneWidget);
    expect(find.text('versionId'), findsOneWidget);
    expect(find.text('storagePath'), findsOneWidget);
    expect(find.text('isNewFile'), findsOneWidget);
  });

  testWidgets('zeigt Entscheidungen als fachlich benannten Chip', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_decisionPromptNode()));

    expect(find.text('Entscheidung'), findsOneWidget);
    expect(find.text('text'), findsNothing);
  });
}

Widget _host(WorkflowNode node) {
  return MaterialApp(
    home: Scaffold(body: NodeOutputChips(node: node)),
  );
}

WorkflowNode _structuredPromptNode() {
  return WorkflowNode(
    id: const NodeId('prompt'),
    title: 'Prompt',
    description: '',
    config: const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.structured,
      choices: [],
      structuredFields: [
        StructuredOutputField(name: 'titel', description: ''),
        StructuredOutputField(name: 'zusammenfassung', description: ''),
        StructuredOutputField(name: '', description: ''),
      ],
    ),
  );
}

WorkflowNode _writeFileNode() {
  return WorkflowNode(
    id: const NodeId('file'),
    title: 'Datei schreiben',
    description: '',
    config: const WriteFileNodeConfig(fileName: '', contentType: ''),
  );
}

WorkflowNode _decisionPromptNode() {
  return WorkflowNode(
    id: const NodeId('decision'),
    title: 'Prompt',
    description: '',
    config: const PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.decision,
      choices: ['Ja', 'Nein'],
    ),
  );
}
