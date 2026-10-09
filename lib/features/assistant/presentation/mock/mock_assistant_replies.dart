import '../../domain/entities/assistant_action_suggestion.dart';
import '../../domain/entities/assistant_message.dart';

/// Feste Agent-Antworten zum Testen des Cursors ohne LLM-Aufruf.
///
/// Aktiv nur im Debug-Modus (`/mock` im Chat). Die Vorschläge haben dasselbe
/// neutrale Format wie die Antwort des Backends.
class MockAssistantReplies {
  const MockAssistantReplies();

  static const trigger = '/mock';

  bool matches(String question) => question.trim().startsWith(trigger);

  AssistantMessage replyTo(String question) {
    return AssistantMessage.agent(
      'Mock-Plan: Ich lege drei Bausteine an und fülle ihre Eingabemasken. '
      'Klicke auf „Ausführen“, um den Cursor zu sehen.',
      actionSuggestions: [
        _command('renameTask', 'Aufgabe umbenennen', {
          'title': 'Mock-Kundenantwort',
        }),
        _command('addNode', 'Texteingabe anlegen', {
          'primitive': 'stringInput',
          'ref': 'text',
          'outputName': 'Text',
          'value': 'Bitte fasse die Anfrage freundlich zusammen.',
        }),
        _command('addNode', 'Prompt anlegen', {
          'primitive': 'prompt',
          'ref': 'prompt',
          'outputName': 'Antwort',
        }),
        _command('configureNode', 'Prompt-Anweisung eintragen', {
          'nodeRef': 'prompt',
          'fields': {
            'instruction':
                'Antworte kurz und höflich auf Deutsch auf '
                '{{Text}}. Nenne am Ende einen nächsten Schritt.',
          },
        }),
        _command('addNode', 'Nachricht senden', {
          'primitive': 'sendChannelMessage',
          'kind': 'email',
          'recipient': 'kunde@example.com',
          'message': 'Hallo, hier ist unsere Antwort: {{Antwort}}',
        }),
      ],
    );
  }

  AssistantActionSuggestion _command(
    String type,
    String label,
    Map<String, Object?> arguments,
  ) {
    return AssistantActionSuggestion(
      target: AssistantActionTarget.taskBuilder,
      type: type,
      label: label,
      arguments: arguments,
    );
  }
}
