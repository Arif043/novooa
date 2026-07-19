import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../entities/skill_draft.dart';
import '../entities/skill_failure.dart';

/// Persistiert Fähigkeiten team-scoped: Metadaten in Firestore, SKILL.md in
/// Firebase Storage. `watchSkills` liefert nur Metadaten — der Inhalt wird
/// beim Öffnen einer Skill gezielt aus Storage geladen.
abstract class SkillRepository {
  Stream<List<Skill>> watchSkills(TeamId teamId);

  Future<Result<Skill, SkillFailure>> loadSkillContent({
    required TeamId teamId,
    required String skillId,
  });

  Future<Result<Skill, SkillFailure>> createSkill({
    required TeamId teamId,
    required SkillDraft draft,
  });

  Future<Result<Skill, SkillFailure>> updateSkill({
    required TeamId teamId,
    required String skillId,
    required SkillDraft draft,
  });

  Future<Result<Unit, SkillFailure>> deleteSkill({
    required TeamId teamId,
    required String skillId,
  });
}
