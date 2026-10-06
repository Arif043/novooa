import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_markdown_preview.dart';

void main() {
  testWidgets('rendert Überschriften ohne Rauten und Fett, Kursiv, Durchgestrichen', (tester) async {
    await _pump(tester, '# Titel\n\nText mit **fett**, *kursiv* und ~~weg~~.');

    expect(_span(tester, 'Titel'), isNotNull);
    expect(_allText(tester), isNot(contains('#')));
    expect(_span(tester, 'fett')!.style!.fontWeight, FontWeight.w700);
    expect(_span(tester, 'kursiv')!.style!.fontStyle, FontStyle.italic);
    expect(_span(tester, 'weg')!.style!.decoration, TextDecoration.lineThrough);
    expect(_allText(tester), isNot(contains('**')));
  });

  testWidgets('rendert Listen, Aufgabenlisten, Tabellen, Zitate und Code', (tester) async {
    await _pump(tester, _richMarkdown);

    expect(find.text('•'), findsWidgets);
    expect(find.text('1.'), findsOneWidget);
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    expect(_span(tester, 'Zitat'), isNotNull);
    expect(_span(tester, 'print(1)')!.style!.fontFamilyFallback, contains('monospace'));
  });

  testWidgets('öffnet verlinkte Notizen über Wiki- und Markdown-Links', (tester) async {
    final selected = <String>[];
    await _pump(tester, 'Siehe [[Leitfaden|den Leitfaden]] und [Projekt](projektwissen.md).', onNoteSelected: selected.add);

    _tap(tester, 'den Leitfaden');
    _tap(tester, 'Projekt');

    expect(selected, ['two', 'one']);
    expect(_allText(tester), isNot(contains('[[')));
  });

  testWidgets('lässt Wiki-Links ohne passende Notiz als Text stehen', (tester) async {
    await _pump(tester, 'Siehe [[Unbekannt]].');

    expect(_allText(tester), contains('[[Unbekannt]]'));
    expect(_span(tester, '[[Unbekannt]]')?.recognizer, isNull);
  });

  testWidgets('öffnet Web-Adressen extern', (tester) async {
    final opened = <Uri>[];
    await _pump(tester, '[Flutter](https://flutter.dev)', openExternal: (uri) async {
      opened.add(uri);
      return true;
    });

    _tap(tester, 'Flutter');

    expect(opened, [Uri.parse('https://flutter.dev')]);
  });

  testWidgets('zeigt einen Hinweis bei leerer Notiz', (tester) async {
    await _pump(tester, '  \n');

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

Future<void> _pump(
  WidgetTester tester,
  String content, {
  ValueChanged<String>? onNoteSelected,
  Future<bool> Function(Uri uri)? openExternal,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: KnowledgeMarkdownPreview(
          content: content,
          notes: _notes,
          onNoteSelected: onNoteSelected ?? (_) {},
          openExternal: openExternal ?? (_) async => false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Iterable<TextSpan> _spans(WidgetTester tester) sync* {
  for (final widget in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
    final root = widget.textSpan;
    if (root == null) continue;
    final spans = <TextSpan>[];
    root.visitChildren((span) {
      if (span is TextSpan) spans.add(span);
      return true;
    });
    yield* spans;
  }
}

TextSpan? _span(WidgetTester tester, String text) {
  for (final span in _spans(tester)) {
    if (span.text == text) return span;
  }
  return null;
}

String _allText(WidgetTester tester) => _spans(tester).map((span) => span.text ?? '').join();

void _tap(WidgetTester tester, String text) {
  final recognizer = _span(tester, text)?.recognizer;
  expect(recognizer, isA<TapGestureRecognizer>(), reason: '„$text“ ist kein Link');
  (recognizer! as TapGestureRecognizer).onTap!();
}

final _notes = [
  KnowledgeNote(
    id: 'one',
    knowledgeBaseId: 'default',
    title: 'Projektwissen',
    path: 'projektwissen.md',
    content: '',
    outgoingLinks: const [],
    updatedAt: DateTime(2026),
  ),
  KnowledgeNote(
    id: 'two',
    knowledgeBaseId: 'default',
    title: 'Leitfaden',
    path: 'leitfaden.md',
    content: '',
    outgoingLinks: const [],
    updatedAt: DateTime(2026),
  ),
];
