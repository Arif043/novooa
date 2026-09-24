import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_output_name_field.dart';

void main() {
  Future<void> pump(WidgetTester tester, WorkflowNode node) {
    return tester.pumpWidget(
      MaterialApp(home: Scaffold(body: NodeOutputNameField(node: node))),
    );
  }

  testWidgets('zeigt den Ausgabenamen als Chip für einen einfachen Baustein', (
    tester,
  ) async {
    await pump(
      tester,
      const WorkflowNode(
        id: NodeId('n1'),
        title: '',
        description: '',
        outputName: 'eingang',
        config: StringInputNodeConfig(value: ''),
      ),
    );

    expect(find.text('{{eingang}}'), findsOneWidget);
  });

  testWidgets('bleibt ausgeblendet ohne Ausgabename', (tester) async {
    await pump(
      tester,
      const WorkflowNode(
        id: NodeId('n1'),
        title: '',
        description: '',
        config: StringInputNodeConfig(value: ''),
      ),
    );

    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets(
    'blendet sich für strukturierte Prompt-Ausgaben aus, auch mit gesetztem outputName',
    (tester) async {
      await pump(
        tester,
        const WorkflowNode(
          id: NodeId('n1'),
          title: '',
          description: '',
          outputName: 'prompt1',
          config: PromptNodeConfig(
            instruction: '',
            outputType: PromptOutputType.structured,
            choices: [],
            structuredFields: [
              StructuredOutputField(name: 'Name', description: ''),
            ],
          ),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
    },
  );

  testWidgets(
    'blendet sich für Dialogeingabe aus, auch mit gesetztem outputName',
    (tester) async {
      await pump(
        tester,
        const WorkflowNode(
          id: NodeId('n1'),
          title: '',
          description: '',
          outputName: 'dialog1',
          config: DialogInputNodeConfig(
            instruction: '',
            fields: [
              DialogInputField(
                name: 'Kundennummer',
                type: DialogInputFieldType.string,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(InputChip), findsNothing);
    },
  );
}
