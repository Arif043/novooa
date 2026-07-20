import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';
import 'internal_assistant_knowledge.dart';

class FirebaseAiAssistantDatasource {
  FirebaseAiAssistantDatasource({
    FirebaseAI? firebaseAI,
    this._knowledge = const InternalAssistantKnowledge(),
  }) : _firebaseAI = firebaseAI ?? FirebaseAI.googleAI();

  static const _modelName = 'gemini-3.5-flash';
  final FirebaseAI _firebaseAI;
  final InternalAssistantKnowledge _knowledge;

  Future<String> ask({
    required AssistantContext context,
    required List<AssistantMessage> history,
    required String question,
  }) async {
    final model = _firebaseAI.generativeModel(
      model: _modelName,
      systemInstruction: Content.text(_systemPromptFor(context)),
      generationConfig: GenerationConfig(
        temperature: 0.2,
        responseMimeType: 'application/json',
        responseJsonSchema: _assistantResponseSchema,
      ),
    );
    final response = await model.generateContent([
      Content.text(_promptFor(history, question)),
    ]);
    return response.text?.trim() ?? 'Ich konnte keine Antwort erzeugen.';
  }

  String _promptFor(List<AssistantMessage> history, String question) {
    final recentHistory = history.take(8).map(_historyLine).join('\n');
    return [
      if (recentHistory.isNotEmpty) 'Bisheriger Verlauf:\n$recentHistory',
      'Nutzerfrage:\n$question',
    ].join('\n\n');
  }

  String _historyLine(AssistantMessage message) {
    final role = switch (message.role) {
      AssistantMessageRole.user => 'Nutzer',
      AssistantMessageRole.agent => 'Agent',
    };
    return '$role: ${message.text}';
  }

  String _systemPromptFor(AssistantContext context) {
    final knowledge = _knowledge.forContext(context);
    return [
      'Du bist der In-App KI-Agent von novooa.',
      'Antworte kurz, konkret und auf Deutsch.',
      'Hilf beim Bauen von Aufgaben, Triggern, Nodes und Wissensbasis-Notizen.',
      'Erkläre Begriffe ohne Fachjargon und schlage kleine nächste Schritte vor.',
      'Aktueller Bereich: ${context.label}.',
      'Route: ${context.route}.',
      'Erfinde keine Funktionen, die novooa noch nicht besitzt.',
      if (context.area == AssistantArea.taskBuilder) _taskBuilderCommandRules,
      if (context.area != AssistantArea.taskBuilder) _emptyCommandRules,
      'Nutze diese interne Wissensbasis als verbindliche Produktinformation:',
      knowledge,
    ].join('\n');
  }
}

const _taskBuilderCommandRules = '''
Wenn der Nutzer einen Geschäftsprozess automatisieren oder eine Aufgabe bauen will,
fülle commands mit einem konkreten Plan.

Erlaubte command types: renameTask, addNode.
Erlaubte primitives: stringInput, prompt, readChannelEvent, sendChannelMessage,
humanApproval, script.
Erlaubte kind-Werte: email, whatsapp, sms.
Der sichtbare Antworttext steht ausschließlich in answer.
''';

const _emptyCommandRules = '''
Setze commands auf eine leere Liste.
Der sichtbare Antworttext steht ausschließlich in answer.
''';

const _assistantResponseSchema = <String, Object?>{
  'type': 'object',
  'additionalProperties': false,
  'required': ['answer', 'commands'],
  'properties': {
    'answer': {'type': 'string'},
    'commands': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['type', 'label'],
        'properties': {
          'type': {
            'type': 'string',
            'enum': ['renameTask', 'addNode'],
          },
          'label': {'type': 'string'},
          'primitive': {
            'type': 'string',
            'enum': [
              'stringInput',
              'prompt',
              'readChannelEvent',
              'sendChannelMessage',
              'humanApproval',
              'script',
            ],
          },
          'kind': {
            'type': 'string',
            'enum': ['email', 'whatsapp', 'sms'],
          },
          'title': {'type': 'string'},
          'referenceName': {'type': 'string'},
          'description': {'type': 'string'},
          'value': {'type': 'string'},
          'instruction': {'type': 'string'},
          'recipient': {'type': 'string'},
          'message': {'type': 'string'},
        },
      },
    },
  },
};
