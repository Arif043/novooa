import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill_failure.dart';
import '../repositories/skill_repository.dart';

class DeleteSkill {
  const DeleteSkill(this._repository);

  final SkillRepository _repository;

  Future<Result<Unit, SkillFailure>> call({
    required TeamId teamId,
    required String skillId,
  }) {
    return _repository.deleteSkill(teamId: teamId, skillId: skillId);
  }
}
