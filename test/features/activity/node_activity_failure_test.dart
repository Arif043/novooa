import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/activity_failure_code.dart';
import 'package:syscat2/features/activity/presentation/widgets/node_activity_failure.dart';

Future<void> _pump(WidgetTester tester, ActivityFailureCode? code) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NodeActivityFailure(
          message: 'Ollama: done_reason length',
          failureCode: code,
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
}
