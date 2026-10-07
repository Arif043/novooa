import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'knowledge_markdown_test_support.dart';

void main() {
  testWidgets(
    'rendert Überschriften ohne Rauten und Fett, Kursiv, Durchgestrichen',
    (tester) async {
      await pumpPreview(
        tester,
        '# Titel\n\nText mit **fett**, *kursiv* und ~~weg~~.',
      );

      expect(previewSpan(tester, 'Titel'), isNotNull);
      expect(previewText(tester), isNot(contains('#')));
      expect(previewSpan(tester, 'fett')!.style!.fontWeight, FontWeight.w700);
      expect(previewSpan(tester, 'kursiv')!.style!.fontStyle, FontStyle.italic);
      expect(
        previewSpan(tester, 'weg')!.style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(previewText(tester), isNot(contains('**')));
    },
  );

  testWidgets('rendert Listen, Aufgabenlisten, Tabellen, Zitate und Code', (
    tester,
  ) async {
    await pumpPreview(tester, _richMarkdown);

    expect(find.text('•'), findsWidgets);
    expect(find.text('1.'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(previewSpan(tester, 'Zitat'), isNotNull);
    expect(
      previewSpan(tester, 'print(1)')!.style!.fontFamilyFallback,
      contains('monospace'),
    );
  });

  testWidgets('öffnet verlinkte Notizen über Wiki- und Markdown-Links', (
    tester,
  ) async {
    final selected = <String>[];
    await pumpPreview(
      tester,
      'Siehe [[Leitfaden|den Leitfaden]] und [Projekt](projektwissen.md).',
      onNoteSelected: selected.add,
    );

    tapPreviewLink(tester, 'den Leitfaden');
    tapPreviewLink(tester, 'Projekt');

    expect(selected, ['two', 'one']);
    expect(previewText(tester), isNot(contains('[[')));
  });

  testWidgets('lässt Wiki-Links ohne passende Notiz als Text stehen', (
    tester,
  ) async {
    await pumpPreview(tester, 'Siehe [[Unbekannt]].');

    expect(previewText(tester), contains('[[Unbekannt]]'));
    expect(previewSpan(tester, '[[Unbekannt]]')?.recognizer, isNull);
  });

  testWidgets('öffnet Web-Adressen extern', (tester) async {
    final opened = <Uri>[];
    await pumpPreview(
      tester,
      '[Flutter](https://flutter.dev)',
      openExternal: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    tapPreviewLink(tester, 'Flutter');

    expect(opened, [Uri.parse('https://flutter.dev')]);
  });

  testWidgets('zeigt einen Hinweis bei leerer Notiz', (tester) async {
    await pumpPreview(tester, '  \n');

    expect(find.textContaining('Diese Notiz ist noch leer'), findsOneWidget);
  });
}

const _richMarkdown = '''
- eins
- zwei

1. erstens

- [x] erledigt
- [ ] offen

| Spalte | Wert |
| --- | --- |
| a | 1 |

> Zitat

```
print(1)
```
''';
