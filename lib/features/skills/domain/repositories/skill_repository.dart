import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../entities/skill_failure.dart';

/// Der Skills-Ordner des Nutzers. `watchSkills` liest den Ordner neu, wenn
/// sich dort etwas ändert (Import, Löschen) oder der Nutzer „Neu einlesen" wählt.
abstract class SkillRepository {
  Stream<List<Skill>> watchSkills(TeamId teamId);

  /// Pfad des Skills-Ordners, wie ihn die Runtime sieht.
  Future<Result<String, SkillFailure>> loadLocation();

  Future<Result<Unit, SkillFailure>> deleteSkill(String name);
}
