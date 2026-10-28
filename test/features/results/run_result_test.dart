import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/results/domain/entities/run_result.dart';

import 'support/run_result_fixtures.dart';

void main() {
  final result = testResult();

  test('innere Bausteine zeigen das Ergebnis der gewählten Runde', () {
    expect(result.resultFor('schritt', const {})?.outputs['value'], {
      'type': 'string',
      'value': 'R-1',
    });
    expect(
      (result.resultFor('schritt', const {'schleife': 1})?.outputs['value']
          as Map)['value'],
      'R-2',
    );
    expect(result.roundCountOf('schleife'), 2);
  });

  test('der nicht genommene Zweig gilt als nicht ausgeführt', () {
    expect(result.stateOf('ja-text', const {}), RunNodeState.succeeded);
    expect(result.stateOf('nein-text', const {}), RunNodeState.notRun);
  });

  test(
    'Folgen zählen nur auf oberster Ebene, damit nichts doppelt erscheint',
    () {
      expect(result.effects, hasLength(2));
    },
  );

  test('Bausteine in einem Zweig gehören zu keiner Schleife', () {
    expect(result.loopOf('schritt'), 'schleife');
    expect(result.loopOf('ja-text'), isNull);
  });
}
