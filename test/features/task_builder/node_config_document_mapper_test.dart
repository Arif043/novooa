import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/infrastructure/models/node_config_document_mapper.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';

void main() {
  test('serialisiert WriteFileNodeConfig', () {
    final mapper = _mapper();
    const config = WriteFileNodeConfig(
      fileName: 'bericht.md',
      contentType: 'text/markdown',
      fileId: 'file.1',
    );

    final document = mapper.toDocument(config);

    expect(document['primitive'], 'writeFile');
    expect(document['fileName'], 'bericht.md');
    expect(document['contentType'], 'text/markdown');
    expect(document['fileId'], 'file.1');
    expect(document['contentTemplate'], '');
  });

  test('deserialisiert WriteFileNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'writeFile',
      'fileName': 'bericht.md',
      'contentType': 'text/markdown',
      'fileId': 'file.1',
      'folderId': 'ordner.1',
    });

    expect(config, isA<WriteFileNodeConfig>());
    final writeFileConfig = config as WriteFileNodeConfig;
    expect(writeFileConfig.fileName, 'bericht.md');
    expect(writeFileConfig.contentType, 'text/markdown');
    expect(writeFileConfig.fileId, 'file.1');
    expect(writeFileConfig.folderId, 'ordner.1');
    expect(writeFileConfig.contentTemplate, '');
  });

  test(
    'bewahrt explizite Eingabe-Templates aller konsumierenden Bausteine',
    () {
      final mapper = _mapper();
      final configs = <NodeConfig>[
        ConditionalNodeConfig.fromChoices([
          'Ja',
        ]).copyWith(valueTemplate: '{{entscheidung.value}}'),
        const IterativeRefinementNodeConfig(
          optimizerPrompt: 'Verbessere.',
          critiquePrompt: 'Prüfe.',
          maxIterations: 2,
          draftTemplate: '{{entwurf.value}}',
        ),
        const HumanApprovalNodeConfig(
          instruction: 'Prüfen',
          reviewTemplate: '{{pruefung.value}}',
        ),
        const ForEachNodeConfig(
          itemsTemplate: '{{erkennung.value}}',
          itemsPointer: '/regions',
          graph: WorkflowGraph(nodes: [], edges: []),
        ),
        const WriteFileNodeConfig(
          contentTemplate: '{{bericht.value}}',
          fileName: 'bericht.txt',
          contentType: 'text/plain',
        ),
      ];

      for (final config in configs) {
        expect(mapper.fromDocument(mapper.toDocument(config)), config);
      }
    },
  );

  test('serialisiert ReadFileNodeConfig', () {
    final document = _mapper().toDocument(
      const ReadFileNodeConfig(file: _attachment),
    );

    expect(document['primitive'], 'readFile');
    expect(document['file'], isA<Map<String, Object?>>());
  });

  test('deserialisiert ReadFileNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'readFile',
      'file': {
        'id': _attachment.id,
        'storagePath': _attachment.storagePath,
        'generation': _attachment.generation,
        'displayName': _attachment.displayName,
        'contentType': _attachment.contentType,
        'sizeBytes': _attachment.sizeBytes,
      },
    });

    expect(config, isA<ReadFileNodeConfig>());
    expect((config as ReadFileNodeConfig).file, _attachment);
  });

  test('serialisiert SendChannelMessageNodeConfig', () {
    final document = _mapper().toDocument(
      const SendChannelMessageNodeConfig(
        kind: ChannelEventKind.whatsapp,
        recipient: '+491234567890',
        message: '{{input}}',
      ),
    );

    expect(document['primitive'], 'sendChannelMessage');
    expect(document['kind'], 'whatsapp');
    expect(document['recipient'], '+491234567890');
    expect(document['message'], '{{input}}');
  });

  test('deserialisiert SendChannelMessageNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'sendChannelMessage',
      'kind': 'sms',
      'recipient': '+491234567890',
      'message': 'Hallo {{name}}',
    });

    expect(config, isA<SendChannelMessageNodeConfig>());
    final sendConfig = config as SendChannelMessageNodeConfig;
    expect(sendConfig.kind, ChannelEventKind.sms);
    expect(sendConfig.recipient, '+491234567890');
    expect(sendConfig.message, 'Hallo {{name}}');
  });

  test('serialisiert NotificationSendNodeConfig', () {
    final document = _mapper().toDocument(
      const NotificationSendNodeConfig(
        title: 'Status',
        message: '{{ergebnis.value}}',
      ),
    );

    expect(document['primitive'], 'notificationSend');
    expect(document['title'], 'Status');
    expect(document['message'], '{{ergebnis.value}}');
  });

  test('deserialisiert NotificationSendNodeConfig', () {
    final config = _mapper().fromDocument({
      'primitive': 'notificationSend',
      'title': 'Status',
      'message': 'Fertig!',
    });

    expect(config, isA<NotificationSendNodeConfig>());
    final notificationConfig = config as NotificationSendNodeConfig;
    expect(notificationConfig.title, 'Status');
    expect(notificationConfig.message, 'Fertig!');
  });

  test('serialisiert und deserialisiert DialogInputNodeConfig', () {
    const config = DialogInputNodeConfig(
      instruction: 'Bitte ergänze die Daten.',
      fields: [
        DialogInputField(name: 'alter', type: DialogInputFieldType.integer),
        DialogInputField(
          name: 'kanal',
          type: DialogInputFieldType.selection,
          options: ['E-Mail', 'SMS'],
        ),
      ],
    );

    final document = _mapper().toDocument(config);
    final restored = _mapper().fromDocument(document) as DialogInputNodeConfig;

    expect(document['primitive'], 'dialogInput');
    expect(restored, config);
  });

  test('ein Bildfeld der Formulareingabe übersteht den Rundweg', () {
    const config = DialogInputNodeConfig(
      instruction: 'Fotografiere den Beleg.',
      fields: [
        DialogInputField(name: 'beleg', type: DialogInputFieldType.image),
      ],
    );

    final document = _mapper().toDocument(config);
    final restored = _mapper().fromDocument(document) as DialogInputNodeConfig;

    expect((document['fields'] as List).single, containsPair('type', 'image'));
    expect(restored, config);
  });

  test('serialisiert und deserialisiert ModelInferenceNodeConfig', () {
    const config = ModelInferenceNodeConfig(
      modelId: 'mobilenet-v3',
      inputMappings: [
        ModelInferenceInputMapping(
          modelInputName: 'pixel_values',
          workflowMapping: '{{eingabe.value}}',
          sourceType: 'tensor',
          dataType: 'float32',
          shape: [1, 3, 224, 224],
        ),
      ],
      settings: [ModelInferenceSetting(name: 'scores_k', valueTemplate: '3')],
    );

    final document = _mapper().toDocument(config);
    final restored =
        _mapper().fromDocument(document) as ModelInferenceNodeConfig;

    expect(document, {
      'primitive': 'modelInference',
      'modelId': 'mobilenet-v3',
      'inputMappings': [
        {
          'modelInputName': 'pixel_values',
          'workflowMapping': '{{eingabe.value}}',
          'sourceType': 'tensor',
          'dataType': 'float32',
          'shape': [1, 3, 224, 224],
        },
      ],
      'settings': [
        {'name': 'scores_k', 'valueTemplate': '3'},
      ],
    });
    expect(restored, config);
  });

  test('liest gespeicherte Ausgangsparameter als Settings', () {
    final restored =
        _mapper().fromDocument({
              'primitive': 'modelInference',
              'modelId': 'squeezenet',
              'outputParameters': [
                {'outputName': 'scores', 'name': 'k', 'value': 5},
                {'outputName': 'logits-out', 'name': 'k', 'value': 2},
              ],
              'settings': [
                {'name': 'scores_k', 'valueTemplate': '7'},
              ],
            })
            as ModelInferenceNodeConfig;

    expect(restored.settings, const [
      ModelInferenceSetting(name: 'scores_k', valueTemplate: '7'),
      ModelInferenceSetting(name: 'logits_out_k', valueTemplate: '2'),
    ]);
    expect(
      _mapper().toDocument(restored).containsKey('outputParameters'),
      isFalse,
    );
  });

  test('serialisiert und deserialisiert SpeechToTextNodeConfig', () {
    const config = SpeechToTextNodeConfig(
      modelId: 'whisper-tiny',
      inputMappings: [
        ModelInferenceInputMapping(
          modelInputName: 'audio',
          workflowMapping: '{{aufnahme.value}}',
          sourceType: 'audio',
          dataType: 'float32',
          shape: [1, 'dynamic'],
        ),
      ],
    );

    final document = _mapper().toDocument(config);
    final restored = _mapper().fromDocument(document);

    expect(document['primitive'], 'speechToText');
    expect(restored, config);
  });

  test('bewahrt konfigurierbare Modellparameter', () {
    const config = ModelInferenceNodeConfig(
      modelId: 'piper',
      settings: [
        ModelInferenceSetting(name: 'lengthScale', valueTemplate: '{{tempo}}'),
      ],
    );

    final restored = _mapper().fromDocument(_mapper().toDocument(config));

    expect(restored, config);
  });

  test('serialisiert PromptNodeConfig mit Wissensanhang', () {
    final document = _mapper().toDocument(
      const PromptNodeConfig(
        instruction: 'Fasse zusammen',
        outputType: PromptOutputType.text,
        choices: [],
        knowledgeAttachments: [_knowledgeAttachment],
      ),
    );

    final notes = document['knowledgeAttachments'] as List<Object?>;
    expect(notes.single, isA<Map<String, Object?>>());
    expect((notes.single! as Map<String, Object?>)['noteId'], 'note.1');
  });

  test(
    'serialisiert und deserialisiert die Sprachmodell-Auswahl eines Prompts',
    () {
      const config = PromptNodeConfig(
        instruction: 'Fasse zusammen',
        languageModelId: 'language-model.1',
        outputType: PromptOutputType.text,
        choices: [],
      );

      final document = _mapper().toDocument(config);
      final restored = _mapper().fromDocument(document) as PromptNodeConfig;

      expect(document['languageModelId'], 'language-model.1');
      expect(restored.languageModelId, 'language-model.1');
    },
  );

  test('deserialisiert PromptNodeConfig mit Wissensanhang', () {
    final config = _mapper().fromDocument({
      'primitive': 'prompt',
      'instruction': 'Fasse zusammen',
      'outputType': 'text',
      'choices': <String>[],
      'knowledgeAttachments': [
        {
          'knowledgeBaseId': 'default',
          'noteId': 'note.1',
          'title': 'Index',
          'path': 'index.md',
        },
      ],
    });

    expect(config, isA<PromptNodeConfig>());
    final promptConfig = config as PromptNodeConfig;
    expect(promptConfig.knowledgeAttachments, [_knowledgeAttachment]);
  });

  test('serialisiert und deserialisiert die Bildausgabe eines Prompts', () {
    final document = _mapper().toDocument(
      const PromptNodeConfig(
        instruction: 'Erstelle ein Bild.',
        outputType: PromptOutputType.image,
        choices: [],
      ),
    );

    final config = _mapper().fromDocument(document) as PromptNodeConfig;

    expect(document['outputType'], 'image');
    expect(config.outputType, PromptOutputType.image);
  });

  test(
    'serialisiert und deserialisiert den Typ strukturierter Prompt-Ausgabefelder',
    () {
      const config = PromptNodeConfig(
        instruction: 'Extrahiere die Rechnungsdaten.',
        outputType: PromptOutputType.structured,
        choices: [],
        structuredFields: [
          StructuredOutputField(
            name: 'summe',
            description: 'Gesamtsumme in Euro',
            type: StructuredFieldType.number,
          ),
          StructuredOutputField(
            name: 'bezahlt',
            description: '',
            type: StructuredFieldType.boolean,
          ),
        ],
      );

      final document = _mapper().toDocument(config);
      final restored = _mapper().fromDocument(document) as PromptNodeConfig;

      expect(document['structuredFields'], [
        {
          'name': 'summe',
          'description': 'Gesamtsumme in Euro',
          'type': 'number',
        },
        {'name': 'bezahlt', 'description': '', 'type': 'boolean'},
      ]);
      expect(restored, config);
    },
  );

  test('strukturierte Prompt-Ausgabefelder ohne persistierten Typ (Altdaten) '
      'fallen auf StructuredFieldType.string zurück', () {
    final config =
        _mapper().fromDocument({
              'primitive': 'prompt',
              'instruction': 'Fasse zusammen',
              'outputType': 'structured',
              'choices': <String>[],
              'structuredFields': [
                {'name': 'titel', 'description': ''},
              ],
            })
            as PromptNodeConfig;

    expect(config.structuredFields.single.type, StructuredFieldType.string);
  });

  test('serialisiert und deserialisiert einen verschachtelten '
      'Branch-Ausdrucksbaum (Klammerung)', () {
    const config = ConditionalNodeConfig(
      branches: [
        ConditionalBranch(
          id: 'branch.1',
          label: 'Bedingung 1',
          graph: WorkflowGraph(nodes: [], edges: []),
          condition: GroupCondition(
            combinator: BooleanCombinator.or,
            children: [
              GroupCondition(
                combinator: BooleanCombinator.and,
                children: [
                  ComparisonCondition(
                    left: '{{x}}',
                    operator: ComparisonOperator.greaterThan,
                    right: '0',
                  ),
                  ComparisonCondition(
                    left: '{{y}}',
                    operator: ComparisonOperator.equals,
                    right: 'ja',
                  ),
                ],
              ),
              ComparisonCondition(
                left: '{{z}}',
                operator: ComparisonOperator.startsWith,
                right: 'immer',
              ),
              ComparisonCondition(
                left: '{{Eingang}}',
                operator: ComparisonOperator.before,
                right: '2026-01-01',
              ),
              ComparisonCondition(
                left: '{{Bezahlt}}',
                operator: ComparisonOperator.isTrue,
                right: '',
              ),
            ],
          ),
        ),
        ConditionalBranch(
          id: 'branch.sonst',
          label: 'Sonst',
          graph: WorkflowGraph(nodes: [], edges: []),
        ),
      ],
    );

    final document = _mapper().toDocument(config);
    final restored = _mapper().fromDocument(document) as ConditionalNodeConfig;

    expect(restored, config);
    expect(restored.branches[1].condition, isNull);
  });

  test(
    'Branches ohne persistiertes condition-Feld (Altdaten) bleiben '
    'branchlos-condition (null) statt eine erfundene Bedingung zu bekommen',
    () {
      final config =
          _mapper().fromDocument({
                'primitive': 'conditionalFlow',
                'valueTemplate': '{{entscheidung.value}}',
                'branches': [
                  {
                    'id': 'branch.1',
                    'label': 'Ja',
                    'graph': {'nodes': [], 'edges': []},
                  },
                ],
              })
              as ConditionalNodeConfig;

      expect(config.branches.single.condition, isNull);
    },
  );

  test('speichert und liest die Sprachmodell-Felder von Text vorlesen', () {
    final mapper = _mapper();
    const config = TextToSpeechNodeConfig(
      modelId: '',
      languageModelId: 'lm-1',
      speechText: 'Hallo {{name.value}}',
      voiceId: 'Puck',
    );

    final document = mapper.toDocument(config);
    final restored = mapper.fromDocument(document) as TextToSpeechNodeConfig;

    expect(document['languageModelId'], 'lm-1');
    expect(document['speechText'], 'Hallo {{name.value}}');
    expect(document['voiceId'], 'Puck');
    expect(restored, config);
    expect(restored.usesLanguageModel, isTrue);
  });

  test('Text vorlesen ohne Sprachmodell bleibt ein lokales ONNX-Modell', () {
    final restored =
        _mapper().fromDocument({'primitive': 'textToSpeech', 'modelId': 'tts'})
            as TextToSpeechNodeConfig;

    expect(restored.usesLanguageModel, isFalse);
    expect(restored.speechText, '');
    expect(restored.voiceId, '');
  });

  test('speichert und liest die Sprachmodell-Felder von Sprache zu Text', () {
    final mapper = _mapper();
    const config = SpeechToTextNodeConfig(
      modelId: '',
      languageModelId: 'lm-2',
      audioTemplate: '{{aufnahme.value}}',
    );

    final restored =
        mapper.fromDocument(mapper.toDocument(config))
            as SpeechToTextNodeConfig;

    expect(restored, config);
    expect(restored.usesLanguageModel, isTrue);
  });

  test('speichert Python-Pakete wie eingegeben und verwirft ungültige', () {
    final mapper = _mapper();
    final config = ScriptNodeConfig(
      script: 'import pandas',
      packages: [PythonPackage.parse('pandas==2.2.3')!],
    );

    final document = mapper.toDocument(config);
    expect(document['packages'], ['pandas==2.2.3']);
    expect(mapper.fromDocument(document), config);
    final withInvalid = mapper.fromDocument({
      ...document,
      'packages': ['pandas==2.2.3', 'https://evil.example/x.whl'],
    });
    expect((withInvalid as ScriptNodeConfig).packages, config.packages);
  });
}

const _attachment = NodeAttachment(
  id: 'file.1:version.1',
  storagePath: 'teams/team.1/files/file.1/versions/version.1/file.txt',
  generation: 'version.1',
  displayName: 'file.txt',
  contentType: 'text/plain',
  sizeBytes: 42,
);

const _knowledgeAttachment = KnowledgeAttachment(
  knowledgeBaseId: 'default',
  noteId: 'note.1',
  title: 'Index',
  path: 'index.md',
);

NodeConfigDocumentMapper _mapper() {
  return NodeConfigDocumentMapper(
    graphToDocument: (_) => const {},
    graphFromDocument: (_) => WorkflowGraph.empty(),
  );
}
