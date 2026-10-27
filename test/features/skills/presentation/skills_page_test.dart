import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/widgets/luminous_card.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/skills/domain/entities/skill.dart';
import 'package:syscat2/features/skills/domain/entities/skill_failure.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_repository.dart';
import 'package:syscat2/features/skills/domain/usecases/delete_skill.dart';
import 'package:syscat2/features/skills/domain/usecases/watch_skills.dart';
import 'package:syscat2/features/skills/presentation/cubits/skills_cubit.dart';
import 'package:syscat2/features/skills/presentation/pages/skills_page.dart';
import 'package:syscat2/features/teams/domain/repositories/team_repository.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

void main() {
  testWidgets('zeigt Fähigkeiten als Karten mit Kopf und Zusammenfassung', (
    tester,
  ) async {
    final repository = _SkillRepository([
      const Skill(
        name: 'ui-taste',
        description: 'Besserer UI-Geschmack.',
        fileCount: 1,
        license: 'MIT',
      ),
      const Skill(
        name: 'pdf',
        description: 'PDFs lesen.',
        fileCount: 3,
        warnings: ['Beschreibung fehlt.'],
      ),
    ]);
    await _pumpPage(tester, repository);

    expect(find.text('Fähigkeiten'), findsOneWidget);
    expect(find.text('2 Fähigkeiten'), findsOneWidget);
    expect(find.byType(LuminousCard), findsNWidgets(2));
    expect(find.text('1 Datei · MIT'), findsOneWidget);
    expect(find.text('3 Dateien'), findsOneWidget);
    expect(find.text('Beschreibung fehlt.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Importieren'), findsOneWidget);
  });

  testWidgets('lädt ohne Fähigkeiten den leeren Zustand mit einer Aktion', (
    tester,
  ) async {
    await _pumpPage(tester, _SkillRepository(const []));

    expect(find.text('Noch keine Fähigkeiten'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Fähigkeiten importieren'),
      findsOneWidget,
    );
    expect(find.byType(LuminousCard), findsNothing);
  });

  testWidgets('bietet bei einem Ladefehler „Erneut versuchen“ an', (
    tester,
  ) async {
    await _pumpPage(tester, _SkillRepository(const [], fails: true));

    expect(find.text('Erneut versuchen'), findsOneWidget);
  });

  testWidgets('löscht eine Fähigkeit erst nach Bestätigung', (tester) async {
    final repository = _SkillRepository([
      const Skill(name: 'pdf', description: 'PDFs lesen.', fileCount: 1),
    ]);
    await _pumpPage(tester, repository);

    await tester.tap(find.byTooltip('Fähigkeit „pdf“ löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Fähigkeit löschen?'), findsOneWidget);
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['pdf']);
  });
}

Future<void> _pumpPage(WidgetTester tester, _SkillRepository repository) async {
  final cubit = SkillsCubit(
    WatchSkills(repository),
    DeleteSkill(repository),
    GetCurrentTeamId(_Teams()),
  );
  addTearDown(cubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(value: cubit, child: const SkillsView()),
      ),
    ),
  );
  await cubit.load();
  await tester.pumpAndSettle();
}

class _Teams implements TeamRepository {
  @override
  Future<TeamId> currentTeamId() async => const TeamId('team-1');
}

class _SkillRepository implements SkillRepository {
  _SkillRepository(this.skills, {this.fails = false});

  final List<Skill> skills;
  final bool fails;
  final deleted = <String>[];

  @override
  Stream<List<Skill>> watchSkills(TeamId teamId) =>
      fails ? Stream.error(StateError('kaputt')) : Stream.value(skills);

  @override
  Future<Result<Unit, SkillFailure>> deleteSkill(String name) async {
    deleted.add(name);
    return const Success(unit);
  }
}
