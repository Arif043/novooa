import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/run_effect.dart';
import 'package:syscat2/features/activity/presentation/widgets/run_effects/run_effect_list.dart';
import 'package:syscat2/features/activity/presentation/widgets/run_effects/run_effect_texts.dart';

const _file = FileWrittenEffect(
  sourceNodeId: 'schreiben',
  iteration: 0,
  fileId: 'f1',
  versionId: 'v1',
  displayName: 'bericht.md',
  isNewFile: true,
);

void main() {
  test('jede Folge wird ein verständlicher Satz, in Schleifen mit Runde', () {
    String text(RunEffect effect) => runEffectPresentation(effect).text;

    expect(text(_file), 'Datei angelegt: bericht.md · Runde 1');
    expect(
      text(
        const MessageSentEffect(
          sourceNodeId: 's',
          channel: MessageChannel.email,
          recipient: 'kunde@example.com',
          subject: 'Rechnung',
        ),
      ),
      'E-Mail an kunde@example.com: „Rechnung“',
    );
    expect(
      text(
        const RecordsChangedEffect(
          sourceNodeId: 'd',
          collectionId: 'c',
          operation: RecordOperation.created,
          count: 3,
        ),
      ),
      '3 Datensätze angelegt',
    );
    expect(
      text(
        const HttpRequestedEffect(
          sourceNodeId: 'h',
          method: 'POST',
          status: 201,
        ),
      ),
      'POST-Anfrage an eine Verbindung (201)',
    );
    expect(
      text(
        const ExternalActionEffect(
          sourceNodeId: 'x',
          plugin: 'shopware',
          action: 'changeOrderStatus',
          label: '10042: completed',
        ),
      ),
      'Shopware: Bestellstatus geändert (10042: completed)',
    );
  });

  testWidgets('nur Datei-Folgen lassen sich öffnen', (tester) async {
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RunEffectList(
            effects: const [
              _file,
              NotificationSentEffect(sourceNodeId: 'n', title: 'Fertig'),
            ],
            onOpenFile: (effect) => opened.add(effect.fileId),
          ),
        ),
      ),
    );

    expect(find.text('Folgen'), findsOneWidget);
    await tester.tap(find.text('Benachrichtigung gesendet: Fertig'));
    await tester.tap(find.text('Datei angelegt: bericht.md · Runde 1'));

    expect(opened, ['f1']);
  });
}
