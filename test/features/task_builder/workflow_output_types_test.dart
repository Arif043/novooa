import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/task_execution_result.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_output_types.dart';

void main() {
  test('primärer Output-Typ folgt dem Baustein', () {
    expect(
      primaryOutputTypeOf(NodeConfig.initial(WorkflowPrimitive.mediaInput)),
      NodeOutputType.media,
    );
    expect(
      primaryOutputTypeOf(NodeConfig.initial(WorkflowPrimitive.writeFile)),
      NodeOutputType.file,
    );
    expect(
      primaryOutputTypeOf(
        NodeConfig.initial(WorkflowPrimitive.tableFromCollection),
      ),
      NodeOutputType.table,
    );
    expect(
      primaryOutputTypeOf(NodeConfig.initial(WorkflowPrimitive.stringInput)),
      NodeOutputType.string,
    );
  });

  test('Nebenoutputs haben den Typ, den der Executor liefert', () {
    expect(secondaryOutputTypeOf('receivedAt'), NodeOutputType.datetime);
    expect(secondaryOutputTypeOf('found'), NodeOutputType.boolean);
    expect(secondaryOutputTypeOf('sizeBytes'), NodeOutputType.number);
    expect(secondaryOutputTypeOf('records'), NodeOutputType.json);
    expect(secondaryOutputTypeOf('sender'), NodeOutputType.string);
  });

  test('strukturierte Felder übernehmen ihren konfigurierten Typ', () {
    const config = PromptNodeConfig(
      instruction: '',
      outputType: PromptOutputType.structured,
      choices: [],
      structuredFields: [
        StructuredOutputField(
          name: 'preis',
          description: '',
          type: StructuredFieldType.number,
        ),
        StructuredOutputField(name: '', description: ''),
      ],
    );

    expect(typedFlatOutputFieldsOf(config), [
      (name: 'preis', type: NodeOutputType.number),
    ]);
  });

  test('Text vorlesen liefert Audio, Modell ausführen strukturierte Daten', () {
    expect(
      primaryOutputTypeOf(TextToSpeechNodeConfig.initial()),
      NodeOutputType.audio,
    );
    expect(
      primaryOutputTypeOf(ModelInferenceNodeConfig.initial()),
      NodeOutputType.json,
    );
    expect(
      primaryOutputTypeOf(SpeechToTextNodeConfig.initial()),
      NodeOutputType.string,
    );
    expect(NodeOutputType.fromName('audio'), NodeOutputType.audio);
  });
}
