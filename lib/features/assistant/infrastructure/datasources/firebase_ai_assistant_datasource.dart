import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/entities/assistant_context.dart';
import '../../domain/entities/assistant_message.dart';

class FirebaseAiAssistantDatasource {
  FirebaseAiAssistantDatasource({FirebaseAI? firebaseAI})
    : _firebaseAI = firebaseAI ?? FirebaseAI.googleAI();

  static const _modelName = 'gemini-3.5-flash';
  final FirebaseAI _firebaseAI;

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
    return [
      'Du bist der In-App KI-Agent von novooa.',
      'Antworte kurz, konkret und auf Deutsch.',
      'Hilf beim Bauen von Aufgaben, Triggern, Nodes und Wissensbasis-Notizen.',
      'Erkläre Begriffe ohne Fachjargon und schlage kleine nächste Schritte vor.',
      'Aktueller Bereich: ${context.label}.',
      'Route: ${context.route}.',
      'Erfinde keine Funktionen, die novooa noch nicht besitzt.',
    ].join('\n');
  }
}
