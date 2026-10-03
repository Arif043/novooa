import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/presentation/widgets/node_activity_values.dart';

void main() {
  testWidgets('zeigt stdout und stderr eines Scripts, stderr rötlich', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light()),
        home: Scaffold(
          body: NodeActivityValues(
            activity: _activity(stdout: 'Passwort: abc\n', stderr: 'Warnung\n'),
          ),
        ),
      ),
    );

    expect(find.text('Script-Ausgabe (stdout)'), findsOneWidget);
    expect(find.text('Fehlerausgabe (stderr)'), findsOneWidget);
    final stdout = tester.widget<SelectableText>(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == 'Passwort: abc',
      ),
    );
    final stderr = tester.widget<SelectableText>(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == 'Warnung',
      ),
    );
    expect(stderr.style?.color, const Color(0xFFB00020));
    expect(stdout.style?.color, isNot(const Color(0xFFB00020)));
  });

  testWidgets('ohne Ausgabe erscheint kein stdout- oder stderr-Block', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NodeActivityValues(activity: _activity())),
      ),
    );

    expect(find.text('Script-Ausgabe (stdout)'), findsNothing);
    expect(find.text('Fehlerausgabe (stderr)'), findsNothing);
  });

  testWidgets('zeigt nur stdout, wenn es keine Fehlerausgabe gibt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NodeActivityValues(activity: _activity(stdout: 'nur Ausgabe')),
        ),
      ),
    );

    expect(find.text('Script-Ausgabe (stdout)'), findsOneWidget);
    expect(find.text('Fehlerausgabe (stderr)'), findsNothing);
  });

  testWidgets('formatiert Node-Werte menschenlesbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NodeActivityValues(activity: _activity())),
      ),
    );

    expect(find.text('Größe'), findsOneWidget);
    expect(find.text('1,5 KB'), findsOneWidget);
    expect(find.text('Neu angelegt'), findsOneWidget);
    expect(find.text('Ja'), findsOneWidget);
    expect(
      find.text('Dokument: Wetterbericht', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.text('Tags: morgen · wichtig', findRichText: true),
      findsOneWidget,
    );
  });
}

TaskActivity _activity({String stdout = '', String stderr = ''}) {
  return TaskActivity(
    id: const UniqueId('node-activity'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.node,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026),
    stdout: stdout,
    stderr: stderr,
    outputs: const {
      'sizeBytes': {'type': 'number', 'value': 1536},
      'isNewFile': {'type': 'boolean', 'value': true},
      'details': {
        'type': 'json',
        'value': {
          'Dokument': 'Wetterbericht',
          'Tags': ['morgen', 'wichtig'],
        },
      },
    },
  );
}
