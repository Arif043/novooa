import '../../domain/entities/assistant_message.dart';
import '../models/assistant_generated_response.dart';

/// Ein Transport, der eine Assistenten-Frage beantwortet, damit
/// `RoutedAssistantRepository` transport-unabhängig bleibt.
abstract interface class AssistantDatasource {
  Future<AssistantGeneratedResponse> ask({
    required List<AssistantMessage> history,
    required String question,
    String? languageCode,
  });
}

/// So viele frühere Nachrichten gehen als Verlauf mit.
const maximumHistoryMessages = 8;

/// Gemeinsamer Anfrage-Body für beide Transporte — identisches
/// Nachrichtenformat, nur die Übertragung unterscheidet sich. Die zuletzt
/// angehängte Nachricht in [history] ist immer die aktuelle [question]
/// selbst (siehe `AssistantCubit.ask`) und wird deshalb nicht doppelt
/// mitgeschickt.
Map<String, Object?> assistantRequestBody({
  required List<AssistantMessage> history,
  required String question,
  String? languageCode,
}) {
  final priorMessages = history.length > 1
      ? history.sublist(0, history.length - 1)
      : const <AssistantMessage>[];
  // Die jüngsten Nachrichten tragen den aktuellen Zusammenhang; ältere fallen weg.
  final recent = priorMessages.length > maximumHistoryMessages
      ? priorMessages.sublist(priorMessages.length - maximumHistoryMessages)
      : priorMessages;
  return {
    'question': question,
    'history': recent.map(_messageMap).toList(growable: false),
    'locale': ?languageCode,
  };
}

Map<String, Object?> _messageMap(AssistantMessage message) {
  return {
    'role': message.role == AssistantMessageRole.agent ? 'agent' : 'user',
    'text': message.text,
  };
}

/// Gemeinsame Antwortvalidierung für beide Transporte.
Map<String, Object?> assistantResponseMapFrom(Map<dynamic, dynamic> response) {
  final value = response.cast<String, Object?>();
  if (value['answer'] is! String) {
    throw StateError('Die KI-Agent-Antwort ist ungültig.');
  }
  return value;
}
