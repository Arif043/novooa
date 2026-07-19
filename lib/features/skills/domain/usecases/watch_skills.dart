import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/skill.dart';
import '../repositories/skill_repository.dart';

class WatchSkills {
  const WatchSkills(this._repository);

  final SkillRepository _repository;

  Stream<List<Skill>> call(TeamId teamId) => _repository.watchSkills(teamId);
}
