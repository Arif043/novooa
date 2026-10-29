import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/knowledge_base/presentation/widgets/knowledge_assistant_message_body.dart';

import 'knowledge_markdown_test_support.dart';

Future<void> _pumpAnswer(
  WidgetTester tester,
  String text, {
  ValueChanged<String>? onNoteSelected,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            KnowledgeAssistantMessageBody(
              text: text,
              notes: previewNotes,
              onNoteSelected: onNoteSelected ?? (_) {},
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('öffnet eine zitierte Notiz über ihren Wiki-Link', (
    tester,
  ) async {
    final selected = <String>[];
    await _pumpAnswer(
      tester,
      'Das steht im [[Leitfaden]].',
      onNoteSelected: selected.add,
    );

    tapPreviewLink(tester, 'Leitfaden');

    expect(selected, ['two']);
  });

  testWidgets('lässt Links auf unbekannte Notizen als Text stehen', (
    tester,
  ) async {
    await _pumpAnswer(tester, 'Siehe [[Unbekannt]].');

    expect(previewSpan(tester, '[[Unbekannt]]')?.recognizer, isNull);
  });
}
