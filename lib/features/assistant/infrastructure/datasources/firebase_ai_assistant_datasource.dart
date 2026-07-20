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
      'Nutze diese interne Wissensbasis als verbindliche Produktinformation:',
      knowledge,
    ].join('\n');
  }
}

const _taskBuilderCommandRules = '''
Wenn der Nutzer einen Geschäftsprozess automatisieren oder eine Aufgabe bauen will,
gib zusätzlich am Ende einen maschinenlesbaren Plan in exakt diesem Format aus:

```novooa_task_plan
{
  "commands": [
    {
      "type": "renameTask",
      "label": "Aufgabe benennen",
      "title": "Kurzer Aufgabenname"
    },
    {
      "type": "addNode",
      "label": "E-Mail lesen",
      "primitive": "readChannelEvent",
      "kind": "email",
      "title": "E-Mail lesen"
    },
    {
      "type": "addNode",
      "label": "Anfrage analysieren",
      "primitive": "prompt",
      "title": "Anfrage analysieren",
      "referenceName": "analyse",
      "instruction": "Analysiere {{email.message}} ..."
    }
  ]
}
```

Erlaubte command types: renameTask, addNode.
Erlaubte primitives: stringInput, prompt, readChannelEvent, sendChannelMessage,
humanApproval, script.
Erlaubte kind-Werte: email, whatsapp, sms.
Keine Markdown-Kommentare innerhalb des JSON. Der sichtbare Antworttext bleibt kurz.
''';
