import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'knowledge_markdown_test_support.dart';

void main() {
  testWidgets('Fußnoten: Verweis als Nummer, Definition als eigener Abschnitt', (tester) async {
    await pumpPreview(tester, 'Satz[^quelle] weiter.\n\n[^quelle]: Die **Quelle**.');

    expect(previewSpan(tester, '1'), isNotNull);
    expect(previewText(tester), isNot(contains('[^quelle]')));
    expect(find.text('1.'), findsOneWidget);
    expect(previewSpan(tester, 'Quelle')!.style!.fontWeight, FontWeight.w700);
    expect(find.byTooltip('Zurück zur Textstelle'), findsOneWidget);
  });

  testWidgets('Fußnoten: springt zur Fußnote und zurück zur Textstelle', (tester) async {
    final filler = List.generate(40, (index) => 'Absatz $index').join('\n\n');
    await pumpPreview(tester, 'Oben[^1]\n\n$filler\n\n[^1]: Ganz unten.');
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);

    tapPreviewLink(tester, '1');
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(0));

    await tester.tap(find.byTooltip('Zurück zur Textstelle'));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, 0);
  });

  testWidgets('Fußnoten: Definitionen in Codeblöcken und Verweise ohne Definition bleiben Text', (tester) async {
    await pumpPreview(tester, 'Ohne Ziel[^fehlt].\n\n```\n[^x]: kein Fußnotentext\n```');

    expect(previewText(tester), contains('[^fehlt]'));
    expect(previewText(tester), contains('[^x]: kein Fußnotentext'));
    expect(find.byTooltip('Zurück zur Textstelle'), findsNothing);
  });

  testWidgets('Formeln im Text und als Block', (tester) async {
    await pumpPreview(tester, r'Es gilt $a^2 + b^2 = c^2$ im Dreieck.' '\n\n\$\$\nE = mc^2\n\$\$');

    expect(find.byType(Math), findsNWidgets(2));
    expect(previewText(tester), isNot(contains(r'$')));
    expect(previewText(tester), contains('im Dreieck.'));
  });

  testWidgets('Beträge mit Dollarzeichen bleiben Text', (tester) async {
    await pumpPreview(tester, r'Kostet 5 $ bis 10 $, in den USA $5 oder $20.');

    expect(find.byType(Math), findsNothing);
    expect(previewText(tester), contains(r'5 $ bis 10 $, in den USA $5 oder $20.'));
  });

  testWidgets('Markierung hinterlegt den Text', (tester) async {
    await pumpPreview(tester, 'Das ist ==wichtig== hier.');

    expect(previewSpan(tester, 'wichtig')!.style!.backgroundColor, isNotNull);
    expect(previewText(tester), isNot(contains('==')));
  });
}
