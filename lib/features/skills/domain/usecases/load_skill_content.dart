import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../entities/skill_failure.dart';
import '../repositories/skill_repository.dart';

class LoadSkillContent {
  const LoadSkillContent(this._repository);

  final SkillRepository _repository;

  Future<Result<Skill, SkillFailure>> call({
    required TeamId teamId,
    required String skillId,
  }) {
    return _repository.loadSkillContent(teamId: teamId, skillId: skillId);
  }
}
