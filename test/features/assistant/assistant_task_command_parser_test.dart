import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/infrastructure/models/assistant_task_command_parser.dart';

void main() {
  group('AssistantTaskCommandParser', () {
    const parser = AssistantTaskCommandParser();

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
