import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_url_source.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_message_sources.dart';

void main() {
  testWidgets('zeigt Quellen mit ihrem Abrufstatus', (tester) async {
    await tester.pumpWidget(
      _testApp([
        AssistantUrlSource(
          url: Uri.parse('https://novooa.de/produkt'),
          status: AssistantUrlSourceStatus.retrieved,
        ),
        AssistantUrlSource(
          url: Uri.parse('https://example.com/artikel'),
          status: AssistantUrlSourceStatus.paywalled,
        ),
      ]),
    );

    expect(find.text('Quellen'), findsOneWidget);
    expect(find.text('Abgerufen: novooa.de'), findsOneWidget);
    expect(find.text('Bezahlschranke: example.com'), findsOneWidget);
  });

  testWidgets('zeigt ohne Quellen keinen Quellenbereich', (tester) async {
    await tester.pumpWidget(_testApp(const []));

    expect(find.text('Quellen'), findsNothing);
  });
}

Widget _testApp(List<AssistantUrlSource> sources) {
  return MaterialApp(
    home: Scaffold(body: AssistantMessageSources(sources: sources)),
  );
}
