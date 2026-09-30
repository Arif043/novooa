import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.text('folderId'), findsOneWidget);
    expect(find.text('isNewFile'), findsOneWidget);
  });

  testWidgets(
    'zeigt für Entscheidungen keine Nebenoutputs — value ist bereits über '
    'den Ausgabenamen erreichbar',
    (tester) async {
      await tester.pumpWidget(_host(_decisionPromptNode()));

      expect(find.text('value'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    },
  );

  testWidgets(
    'zeigt für Bild-Prompts keine Nebenoutputs — value ist bereits über '
    'den Ausgabenamen erreichbar',
    (tester) async {
      await tester.pumpWidget(_host(_imagePromptNode()));

      expect(find.text('value'), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
    },
  );

  testWidgets(
    'zeigt bei der Modell-Inferenz nur den Nebenoutput modelId, nicht value',
    (tester) async {
      await tester.pumpWidget(_host(_modelInferenceNode()));

      expect(find.text('value'), findsNothing);
      expect(find.text('modelId'), findsOneWidget);
    },
  );

  testWidgets(
    'kopiert die Dot-Pfad-Referenz eines Nebenoutputs beim Antippen',
    (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(_host(_saveDocumentNode(outputName: 'speichern1')));
      await tester.tap(find.text('created'));

      expect(copied, ['{{speichern1.created}}']);
    },
  );

  testWidgets(
    'kopiert die flache Referenz eines strukturierten Feldes ohne '
    'Knotennamen beim Antippen',
    (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(_host(_structuredPromptNode()));
      await tester.tap(find.text('titel'));

      expect(copied, ['{{titel}}']);
    },
  );
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

WorkflowNode _imagePromptNode() {
  return WorkflowNode(
    id: const NodeId('image'),
    title: 'Bild erstellen',
    description: '',
    config: const PromptNodeConfig(
      instruction: 'Erstelle ein Bild.',
      outputType: PromptOutputType.image,
      choices: [],
    ),
  );
}

WorkflowNode _modelInferenceNode() {
  return WorkflowNode(
    id: const NodeId('model'),
    title: 'Modell ausführen',
    description: '',
    config: const ModelInferenceNodeConfig(modelId: 'mobilenet-v3'),
  );
}

WorkflowNode _saveDocumentNode({required String outputName}) {
  return WorkflowNode(
    id: const NodeId('save'),
    title: 'Datensatz speichern',
    description: '',
    outputName: outputName,
    config: const SaveDocumentNodeConfig(
      collectionName: 'kunden',
      filters: [],
      fields: [DocumentFieldAssignment(field: 'name', value: '')],
    ),
  );
}
