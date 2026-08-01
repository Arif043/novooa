import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/presentation/widgets/task_activity_history.dart';

void main() {
  testWidgets('zeigt nur Aufgaben und oeffnet ihre Baustein-Aktivitaeten', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskActivityHistory(
            activities: [
              _taskActivity(),
              _nodeActivity(),
              _otherNodeActivity(),
            ],
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('Tagesbericht'), findsOneWidget);
    expect(find.text('Prompt ausgeführt'), findsNothing);

    await tester.tap(find.text('Tagesbericht'));
    await tester.pumpAndSettle();

    expect(find.text('Prompt ausgeführt'), findsOneWidget);
    expect(find.text('Zusammenfassung'), findsOneWidget);
    expect(find.text('Wetter: sonnig'), findsOneWidget);
    expect(find.text('Validierung ausgeführt'), findsNothing);
  });
}

TaskActivity _taskActivity() {
  return TaskActivity(
    id: const UniqueId('task-activity'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.task,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026),
  );
}

TaskActivity _nodeActivity() {
  return TaskActivity(
    id: const UniqueId('node-activity'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.node,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026, 1, 1, 12),
    nodeId: 'prompt-1',
    primitive: 'prompt',
    outputs: const {'Zusammenfassung': 'Wetter: sonnig'},
  );
}

TaskActivity _otherNodeActivity() {
  return TaskActivity(
    id: const UniqueId('other-node-activity'),
    runId: const UniqueId('run-2'),
    taskId: 'task-2',
    taskTitle: 'Andere Aufgabe',
    target: TaskActivityTarget.node,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026, 1, 1, 13),
    nodeId: 'validation-1',
    primitive: 'validation',
  );
}
