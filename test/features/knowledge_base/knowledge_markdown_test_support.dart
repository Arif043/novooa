import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/domain/entities/knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_markdown_preview.dart';

Future<void> pumpPreview(
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
          notes: previewNotes,
          onNoteSelected: onNoteSelected ?? (_) {},
          openExternal: openExternal ?? (_) async => false,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Iterable<TextSpan> previewSpans(WidgetTester tester) sync* {
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

TextSpan? previewSpan(WidgetTester tester, String text) {
  for (final span in previewSpans(tester)) {
    if (span.text == text) return span;
  }
  return null;
}

String previewText(WidgetTester tester) => previewSpans(tester).map((span) => span.text ?? '').join();

void tapPreviewLink(WidgetTester tester, String text) {
  final recognizer = previewSpan(tester, text)?.recognizer;
  expect(recognizer, isA<TapGestureRecognizer>(), reason: '„$text“ ist kein Link');
  (recognizer! as TapGestureRecognizer).onTap!();
}

final previewNotes = [
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
