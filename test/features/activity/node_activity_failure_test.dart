import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/activity_failure_code.dart';
import 'package:syscat2/features/activity/presentation/widgets/node_activity_failure.dart';

Future<void> _pump(
  WidgetTester tester,
  ActivityFailureCode? code, {
  Map<String, String> details = const {},
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NodeActivityFailure(
          message: 'Ollama: done_reason length',
          failureCode: code,
          failureDetails: details,
        ),
      ),
    ),
  );
}

void main() {
  test('unbekannte Codes ergeben keinen Fehlercode', () {
    expect(ActivityFailureCode.fromName('unknown'), isNull);
    expect(ActivityFailureCode.fromName(null), isNull);
    expect(
      ActivityFailureCode.fromName('timedOut'),
      ActivityFailureCode.timedOut,
    );
  });

  testWidgets('erklärt einen bekannten Code und zeigt die Details darunter', (
    tester,
  ) async {
    await _pump(tester, ActivityFailureCode.responseTruncated);

    expect(
      find.textContaining('Die Antwort wurde abgeschnitten'),
      findsOneWidget,
    );
    expect(find.text('Technische Details'), findsOneWidget);
    expect(find.text('Ollama: done_reason length'), findsOneWidget);
  });

  testWidgets('ohne Code bleibt es beim Text der Runtime', (tester) async {
    await _pump(tester, null);

    expect(find.text('Fehler'), findsOneWidget);
    expect(find.text('Technische Details'), findsNothing);
    expect(find.text('Ollama: done_reason length'), findsOneWidget);
  });

  testWidgets('setzt Operator, erwartete Art und Wert in die Erklärung ein', (
    tester,
  ) async {
    await _pump(
      tester,
      ActivityFailureCode.conditionOperandMismatch,
      details: const {
        'operator': 'before',
        'expected': 'date',
        'received': '29.09.2026',
      },
    );

    expect(
      find.textContaining(
        'Der Vergleich „ist vor“ braucht ein Datum (JJJJ-MM-TT), '
        'erhalten: „29.09.2026“',
      ),
      findsOneWidget,
    );
  });
}
