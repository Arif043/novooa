import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/run_effect.dart';
import 'package:syscat2/features/activity/infrastructure/models/run_effect_mapper.dart';

void main() {
  test('liest jede bekannte Art mit Herkunft und Runde', () {
    final effects = runEffectsFrom([
      {
        'kind': 'fileWritten',
        'sourceNodeId': 'schreiben',
        'iteration': 2,
        'fileId': 'f1',
        'versionId': 'v1',
        'displayName': 'bericht.md',
        'isNewFile': true,
      },
      {
        'kind': 'messageSent',
        'sourceNodeId': 'senden',
        'channel': 'email',
        'recipient': 'a@b.de',
        'subject': 'Hallo',
      },
      {'kind': 'notificationSent', 'sourceNodeId': 'n', 'title': 'Fertig'},
      {
        'kind': 'recordsChanged',
        'sourceNodeId': 'd',
        'collectionId': 'c',
        'operation': 'updated',
        'count': 1,
        'documentId': 'x',
      },
      {
        'kind': 'httpRequested',
        'sourceNodeId': 'h',
        'method': 'POST',
        'status': 201,
        'host': 'api.example.com',
      },
      {
        'kind': 'externalAction',
        'sourceNodeId': 's',
        'plugin': 'shopware',
        'action': 'updateProduct',
        'label': 'SW-1',
      },
    ]);

    expect(effects.map((effect) => effect.runtimeType), [
      FileWrittenEffect,
      MessageSentEffect,
      NotificationSentEffect,
      RecordsChangedEffect,
      HttpRequestedEffect,
      ExternalActionEffect,
    ]);
    final file = effects.first as FileWrittenEffect;
    expect(
      (file.sourceNodeId, file.iteration, file.isNewFile),
      ('schreiben', 2, true),
    );
  });

  test('unbekannte Arten und unvollständige Einträge fallen weg', () {
    final effects = runEffectsFrom([
      {'kind': 'teleportiert', 'sourceNodeId': 'x'},
      {'kind': 'notificationSent', 'title': 'ohne Herkunft'},
      {'kind': 'messageSent', 'sourceNodeId': 's', 'channel': 'brieftaube'},
      'kein Objekt',
    ]);

    expect(effects, isEmpty);
    expect(runEffectsFrom(null), isEmpty);
  });
}
