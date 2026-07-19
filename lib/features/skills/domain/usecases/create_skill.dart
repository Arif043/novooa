import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../entities/skill_draft.dart';
import '../entities/skill_failure.dart';
import '../repositories/skill_repository.dart';

class CreateSkill {
  const CreateSkill(this._repository);

  final SkillRepository _repository;

  Future<Result<Skill, SkillFailure>> call({
    required TeamId teamId,
    required SkillDraft draft,
  }) {
    return _repository.createSkill(teamId: teamId, draft: draft);
  }
}
