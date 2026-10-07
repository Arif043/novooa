import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

import 'knowledge_markdown_test_support.dart';

void main() {
  testWidgets('Formeln im Text und als Block', (tester) async {
    await pumpPreview(
      tester,
      r'Es gilt $a^2 + b^2 = c^2$ im Dreieck.'
      '\n\n\$\$\nE = mc^2\n\$\$',
    );

    expect(find.byType(Math), findsNWidgets(2));
    expect(previewText(tester), isNot(contains(r'$')));
    expect(previewText(tester), contains('im Dreieck.'));
  });

  testWidgets('Beträge mit Dollarzeichen bleiben Text', (tester) async {
    await pumpPreview(tester, r'Kostet 5 $ bis 10 $, in den USA $5 oder $20.');

    expect(find.byType(Math), findsNothing);
    expect(
      previewText(tester),
      contains(r'5 $ bis 10 $, in den USA $5 oder $20.'),
    );
  });

  testWidgets('Markierung hinterlegt den Text', (tester) async {
    await pumpPreview(tester, 'Das ist ==wichtig== hier.');

    expect(previewSpan(tester, 'wichtig')!.style!.backgroundColor, isNotNull);
    expect(previewText(tester), isNot(contains('==')));
  });
}
