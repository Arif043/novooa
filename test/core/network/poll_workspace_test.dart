import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';

void main() {
  test('liefert aufeinanderfolgende Werte im Intervall', () async {
    var counter = 0;
    final stream = pollWorkspace(
      () async => ++counter,
      interval: const Duration(milliseconds: 10),
    );

    final values = await stream.take(3).toList();

    expect(values, [1, 2, 3]);
  });

  test(
    'ein fehlgeschlagener Tick beendet den Stream nicht dauerhaft',
    () async {
      var attempt = 0;
      final stream = pollWorkspace(() async {
        attempt++;
        if (attempt == 2) throw Exception('vorübergehend nicht erreichbar');
        return attempt;
      }, interval: const Duration(milliseconds: 10));

      final values = <int>[];
      final errors = <Object>[];
      final done = Completer<void>();
      final subscription = stream.listen(
        values.add,
        onError: errors.add,
      );
      Timer(const Duration(milliseconds: 60), () {
        subscription.cancel();
        done.complete();
      });
      await done.future;

      // Tick 2 schlägt fehl (Fehler landet in `errors`), Tick 1 und
      // mindestens Tick 3 liefern trotzdem weiterhin Werte — der Stream
      // "stirbt" also nicht am ersten Fehler.
      expect(errors, hasLength(1));
      expect(values, contains(1));
      expect(values, contains(3));
    },
  );

  test('pollt nicht mehr, sobald niemand mehr zuhört', () async {
    var callCount = 0;
    final stream = pollWorkspace(
      () async => ++callCount,
      interval: const Duration(milliseconds: 10),
    );

    final subscription = stream.listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 25));
    await subscription.cancel();
    final countAtCancel = callCount;
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(callCount, countAtCancel);
  });
}
