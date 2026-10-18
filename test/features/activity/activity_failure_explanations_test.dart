import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/activity_failure_code.dart';
import 'package:syscat2/features/activity/presentation/widgets/activity_failure_explanations.dart';
import 'package:syscat2/features/activity/presentation/widgets/activity_failure_labels.dart';

void main() {
  test('jeder Code hat eine Erklärung', () {
    expect(
      activityFailureExplanations.keys.toSet(),
      ActivityFailureCode.values.toSet(),
    );
  });

  test('übersetzt die Felder in die Erklärung', () {
    expect(
      ActivityFailureCode.settingMissing.localizedExplanation({
        'setting': 'mailbox',
      }),
      'Im Baustein fehlt eine Angabe: verbundenes Postfach.',
    );
    expect(
      ActivityFailureCode.valueTypeMismatch.localizedExplanation({
        'target': 'modelInput',
        'expected': 'image',
        'name': 'bild',
      }),
      'Ein Wert für eine Modelleingabe hat den falschen Typ: '
      'erwartet wird ein Bild („bild“).',
    );
    expect(
      ActivityFailureCode.httpStatusFailed.localizedExplanation({
        'status': '404',
        'excerpt': 'nicht gefunden',
      }),
      'Die HTTP-Anfrage ist mit Status 404 fehlgeschlagen.',
    );
  });

  test('ein unbekannter Detailwert erscheint roh', () {
    expect(
      ActivityFailureCode.triggerMismatch.localizedExplanation({
        'trigger': 'signal',
      }),
      contains('nicht durch signal gestartet'),
    );
  });

  test('eine gescheiterte Runde einer Schleife steht dahinter', () {
    expect(
      ActivityFailureCode.settingMissing.localizedExplanation({
        'setting': 'recipient',
        'iteration': '2',
      }),
      'Im Baustein fehlt eine Angabe: Empfänger. (Durchlauf 3)',
    );
  });
}
