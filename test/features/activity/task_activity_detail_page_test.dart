import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/presentation/widgets/task_activity_detail_page.dart';

TaskActivity _node(
  String id,
  String nodeId,
  TaskActivityStatus status, {
  String? message,
  String stdout = '',
  String stderr = '',
  int second = 0,
}) {
  return TaskActivity(
    id: UniqueId(id),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.node,
    status: status,
    occurredAt: DateTime.utc(2026, 1, 1, 0, 0, second),
    nodeId: nodeId,
    primitive: 'script',
    message: message,
    stdout: stdout,
    stderr: stderr,
  );
}

TaskActivity _run(TaskActivityStatus status, {String? message}) {
  return TaskActivity(
    id: const UniqueId('run'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Tagesbericht',
    target: TaskActivityTarget.task,
    status: status,
    occurredAt: DateTime.utc(2026),
    message: message,
  );
}

Future<void> _open(
  WidgetTester tester,
  TaskActivity run,
  List<TaskActivity> nodes,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorScheme: const ColorScheme.light()),
      home: TaskActivityDetailPage(taskActivity: run, nodeActivities: nodes),
    ),
  );
}

void main() {
  testWidgets(
    'der fehlgeschlagene Baustein steht an seiner Position mit Fehler und Ausgabe',
    (tester) async {
      await _open(
        tester,
        _run(TaskActivityStatus.failed, message: 'Zeile 2: ValueError: kaputt'),
        [
          _node(
            'n1',
            'node.1',
            TaskActivityStatus.succeeded,
            stdout: 'Schritt 1\n',
          ),
          _node(
            'n2',
            'node.2',
            TaskActivityStatus.failed,
            message: 'Zeile 2: ValueError: kaputt',
            stdout: 'kurz davor\n',
            stderr: 'Warnung\n',
            second: 1,
          ),
        ],
      );

      expect(find.text('Erfolgreich · node.1'), findsOneWidget);
      expect(find.text('Fehlgeschlagen · node.2'), findsOneWidget);
      expect(find.text('Script fehlgeschlagen'), findsOneWidget);
      expect(find.text('Fehler'), findsOneWidget);
      expect(find.text('Zeile 2: ValueError: kaputt'), findsOneWidget);
      expect(find.text('kurz davor'), findsOneWidget);
      expect(find.text('Warnung'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Erfolgreich · node.1')).dy,
        lessThan(tester.getTopLeft(find.text('Fehlgeschlagen · node.2')).dy),
        reason: 'die Reihenfolge ist die der Bausteine',
      );
      expect(
        find.text('Tagesbericht'),
        findsNWidgets(1),
        reason: 'keine zusätzliche Lauf-Kachel, der Fehler gehört zum Baustein',
      );
    },
  );

  testWidgets(
    'ein Fehler ohne Baustein steht als Lauf-Eintrag oben, die Bausteine davor darunter',
    (tester) async {
      await _open(
        tester,
        _run(TaskActivityStatus.failed, message: 'Der Plan ist ungültig.'),
        [_node('n1', 'node.1', TaskActivityStatus.succeeded)],
      );

      expect(find.text('Der Plan ist ungültig.'), findsOneWidget);
      expect(find.text('Erfolgreich · node.1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Der Plan ist ungültig.')).dy,
        lessThan(tester.getTopLeft(find.text('Erfolgreich · node.1')).dy),
      );
    },
  );

  testWidgets('ein fehlgeschlagener Lauf ohne Bausteine zeigt nur den Fehler', (
    tester,
  ) async {
    await _open(
      tester,
      _run(TaskActivityStatus.failed, message: 'sofort'),
      const [],
    );

    expect(find.text('sofort'), findsOneWidget);
    expect(
      find.textContaining('noch keine Baustein-Aktivitäten'),
      findsNothing,
    );
  });

  testWidgets('ein erfolgreicher Lauf zeigt keine zusätzliche Lauf-Kachel', (
    tester,
  ) async {
    await _open(tester, _run(TaskActivityStatus.succeeded), [
      _node('n1', 'node.1', TaskActivityStatus.succeeded),
    ]);

    expect(find.text('Erfolgreich · node.1'), findsOneWidget);
    expect(
      find.text('Tagesbericht'),
      findsOneWidget,
      reason: 'nur der Titel der AppBar, keine Lauf-Kachel',
    );
  });
}
