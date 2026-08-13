import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/infrastructure/models/assistant_task_command_parser.dart';

void main() {
  group('AssistantTaskCommandParser', () {
    const parser = AssistantTaskCommandParser();

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
      expect(answer.commands, hasLength(1));
      expect(answer.commands.single.type, 'renameTask');
      expect(answer.commands.single.title, 'Support');
    });

    test('liest strukturierte JSON-Antwort ohne Commands', () {
      final answer = parser.parse('''
{"answer":"Ich kann dir helfen.","commands":[]}
''');

      expect(answer.text, 'Ich kann dir helfen.');
      expect(answer.commands, isEmpty);
    });

    test('liest Wissensbasis-Commands aus strukturierter JSON-Antwort', () {
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

      expect(answer.knowledgeCommands, hasLength(1));
      expect(answer.knowledgeCommands.single.type, 'createKnowledgeNote');
      expect(answer.knowledgeCommands.single.title, 'Projektstart');
    });

    test('entfernt Command-Block aus sichtbarem Text', () {
      final answer = parser.parse('''
Ich entwerfe dir eine Aufgabe.

```novooa_task_plan
{"commands":[{"type":"renameTask","label":"Aufgabe benennen","title":"Support"}]}
```
''');

      expect(answer.text, 'Ich entwerfe dir eine Aufgabe.');
      expect(answer.commands, hasLength(1));
      expect(answer.commands.single.type, 'renameTask');
      expect(answer.commands.single.title, 'Support');
    });

    test('ignoriert ungültiges Command-JSON', () {
      final answer = parser.parse('''
Ich kann helfen.

```novooa_task_plan
{not-json}
```
''');

      expect(answer.text, 'Ich kann helfen.');
      expect(answer.commands, isEmpty);
    });
  });
}
