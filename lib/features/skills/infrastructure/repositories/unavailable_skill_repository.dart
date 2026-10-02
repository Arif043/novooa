import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/skill.dart';
import '../../domain/entities/skill_failure.dart';
import '../../domain/repositories/skill_repository.dart';

/// Für Betriebsvarianten ohne Skills-Ordner (Cloud): keine Skills, kein Speicher.
class UnavailableSkillRepository implements SkillRepository {
  const UnavailableSkillRepository();

  static const _failure = SkillFailure(
    'Fähigkeiten sind in dieser Betriebsvariante noch nicht verfügbar.',
  );

  @override
  Stream<List<Skill>> watchSkills(TeamId teamId) => Stream.value(const []);

  @override
  Future<Result<Unit, SkillFailure>> deleteSkill(String name) async =>
      const Error(_failure);
}
