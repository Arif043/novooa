import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../entities/skill_failure.dart';

/// Das Skills-Verzeichnis der Anwendung. `watchSkills` liest es neu, wenn sich
/// dort etwas ändert (Import, Löschen).
abstract class SkillRepository {
  Stream<List<Skill>> watchSkills(TeamId teamId);

  Future<Result<Unit, SkillFailure>> deleteSkill(String name);
}
