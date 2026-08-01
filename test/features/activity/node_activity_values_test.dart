import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/presentation/widgets/node_activity_values.dart';

void main() {
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

TaskActivity _activity() {
  return TaskActivity(
    id: const UniqueId('node-activity'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.node,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026),
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
