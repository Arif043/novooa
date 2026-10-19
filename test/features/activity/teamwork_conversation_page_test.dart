import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/core/theme/agent_colors.dart';
import 'package:syscat2/core/widgets/noovi/noovi_avatar.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';
import 'package:syscat2/features/activity/domain/entities/task_activity.dart';
import 'package:syscat2/features/activity/presentation/pages/teamwork_conversation_page.dart';
import 'package:syscat2/features/activity/presentation/widgets/activity_tile.dart';

final _conversation = [
  TeamworkConversationEntry(
    kind: TeamworkConversationKind.task,
    occurredAt: DateTime.utc(2026, 10, 19, 8),
    memberName: 'Elektriker',
    text: 'Prüfe den Schaltplan.',
    expectedResult: 'Korrekt ja oder nein.',
    boundaries: 'Keine Kosten.',
  ),
  TeamworkConversationEntry(
    kind: TeamworkConversationKind.answer,
    occurredAt: DateTime.utc(2026, 10, 19, 8, 1),
    memberId: 'e1',
    memberName: 'Elektriker',
    text: 'Der Plan ist korrekt.',
    duration: const Duration(milliseconds: 27900),
  ),
  TeamworkConversationEntry(
    kind: TeamworkConversationKind.reviewRejected,
    occurredAt: DateTime.utc(2026, 10, 19, 8, 2),
    text: 'Die Kosten fehlen.',
    round: 1,
  ),
];

TaskActivity _teamwork({
  List<TeamworkConversationEntry> conversation = const [],
}) {
  return TaskActivity(
    id: const UniqueId('a1'),
    runId: const UniqueId('run-1'),
    taskId: 'task-1',
    taskTitle: 'Schaltplan prüfen',
    target: TaskActivityTarget.node,
    status: TaskActivityStatus.succeeded,
    occurredAt: DateTime.utc(2026, 10, 19, 8, 3),
    nodeId: 'node.1',
    primitive: 'teamwork',
    conversation: conversation,
  );
}

Future<void> _pump(WidgetTester tester, Widget home) {
  return tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorScheme: const ColorScheme.light()),
      home: Scaffold(body: SingleChildScrollView(child: home)),
    ),
  );
}

void main() {
  testWidgets('the button opens the conversation on its own page', (
    tester,
  ) async {
    await _pump(
      tester,
      ActivityTile(activity: _teamwork(conversation: _conversation)),
    );

    await tester.tap(find.text('Gespräch der Mitarbeiter anzeigen'));
    await tester.pumpAndSettle();

    expect(find.byType(TeamworkConversationPage), findsOneWidget);
    expect(find.text('Orchestrator → Elektriker'), findsOneWidget);
    expect(find.text('Elektriker → Orchestrator'), findsOneWidget);
    expect(find.text('Prüfung → Orchestrator'), findsOneWidget);
    expect(find.text('Erwartetes Ergebnis'), findsOneWidget);
    expect(find.text('Keine Kosten.'), findsOneWidget);
    expect(find.textContaining('nach 27.9 s'), findsOneWidget);
    expect(find.textContaining('Prüfung 1 beanstandet'), findsOneWidget);
    final avatars = tester
        .widgetList<NooviAvatar>(find.byType(NooviAvatar))
        .toList();
    expect(avatars.map((avatar) => avatar.pose), [
      NooviPose.fly,
      NooviPose.present,
      NooviPose.thinking,
    ]);
    expect(avatars[1].ringColor, AgentColors.memberColor('e1'));
  });

  testWidgets('without a conversation there is no button', (tester) async {
    await _pump(tester, ActivityTile(activity: _teamwork()));

    expect(find.text('Gespräch der Mitarbeiter anzeigen'), findsNothing);
  });

  testWidgets('an empty conversation shows a hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: TeamworkConversationPage(activity: _teamwork())),
    );

    expect(
      find.text('Für diesen Baustein wurde kein Gespräch aufgezeichnet.'),
      findsOneWidget,
    );
  });
}
