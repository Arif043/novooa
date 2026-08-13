import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/infrastructure/models/assistant_action_suggestion_parser.dart';

void main() {
  group('AssistantActionSuggestionParser', () {
    const parser = AssistantActionSuggestionParser();

    test('liest strukturierte JSON-Antwort', () {
      final answer = parser.parse('''
{
  "answer": "Ich entwerfe dir eine Aufgabe.",
  "commands": [
    {
      "type": "renameTask",
      "label": "Aufgabe benennen",
      "title": "Support"
    }
  ]
}
''');

      expect(answer.text, 'Ich entwerfe dir eine Aufgabe.');
      expect(answer.actionSuggestions, hasLength(1));
      expect(answer.actionSuggestions.single.type, 'renameTask');
      expect(
        answer.actionSuggestions.single.stringArgument('title'),
        'Support',
      );
    });

    test('liest strukturierte JSON-Antwort ohne Commands', () {
      final answer = parser.parse('''
{"answer":"Ich kann dir helfen.","commands":[]}
''');

      expect(answer.text, 'Ich kann dir helfen.');
      expect(answer.actionSuggestions, isEmpty);
    });

    test('liest Wissensbasis-Vorschlaege aus strukturierter JSON-Antwort', () {
      final answer = parser.parse('''
{
  "answer": "Ich lege die Notiz an.",
  "commands": [],
  "knowledgeCommands": [
    {
      "type": "createKnowledgeNote",
      "label": "Notiz erstellen",
      "title": "Projektstart",
      "content": "# Projektstart"
    }
  ]
}
''');

      expect(answer.actionSuggestions, hasLength(1));
      expect(answer.actionSuggestions.single.type, 'createKnowledgeNote');
      expect(
        answer.actionSuggestions.single.stringArgument('title'),
        'Projektstart',
      );
    });

    test('entfernt Command-Block aus sichtbarem Text', () {
      final answer = parser.parse('''
Ich entwerfe dir eine Aufgabe.

```novooa_task_plan
{"commands":[{"type":"renameTask","label":"Aufgabe benennen","title":"Support"}]}
```
''');

      expect(answer.text, 'Ich entwerfe dir eine Aufgabe.');
      expect(answer.actionSuggestions, hasLength(1));
      expect(answer.actionSuggestions.single.type, 'renameTask');
      expect(
        answer.actionSuggestions.single.stringArgument('title'),
        'Support',
      );
    });

    test('ignoriert ungültiges Command-JSON', () {
      final answer = parser.parse('''
Ich kann helfen.

```novooa_task_plan
{not-json}
```
''');

      expect(answer.text, 'Ich kann helfen.');
      expect(answer.actionSuggestions, isEmpty);
    });
  });
}
