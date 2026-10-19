import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/employees/domain/entities/employee.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/teamwork/team_member_card.dart';

void main() {
  Future<List<TeamMember>> pump(
    WidgetTester tester, {
    TeamMember member = const TeamMember(employeeId: 'e1'),
    Employee? employee,
    bool lookupReady = true,
  }) async {
    final changes = <TeamMember>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TeamMemberCard(
              member: member,
              employee: employee,
              lookupReady: lookupReady,
              onChanged: changes.add,
              onRemove: () {},
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  const recherche = Employee(
    id: 'e1',
    name: 'Recherche',
    constraint: 'Gründlich',
    skillNames: [],
  );

  testWidgets('ohne Zuständigkeit sagt die Karte, warum sie nötig ist', (
    tester,
  ) async {
    final changes = await pump(tester, employee: recherche);

    expect(find.text('Recherche'), findsOneWidget);
    expect(
      find.textContaining('danach vergibt der Orchestrator'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'Findet Fakten');
    expect(changes.single.responsibility, 'Findet Fakten');
    expect(changes.single.employeeId, 'e1');
  });

  testWidgets('ein gelöschter Mitarbeiter wird erst nach dem Laden gemeldet', (
    tester,
  ) async {
    const member = TeamMember(employeeId: 'weg', responsibility: 'x');

    await pump(tester, member: member, lookupReady: false);
    expect(find.text('…'), findsOneWidget);

    await pump(tester, member: member);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(
      find.textContaining('danach vergibt der Orchestrator'),
      findsNothing,
    );
  });
}
