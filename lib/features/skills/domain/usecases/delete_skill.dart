import 'package:multiple_result/multiple_result.dart';

import '../entities/skill_failure.dart';
import '../repositories/skill_repository.dart';

class DeleteSkill {
  const DeleteSkill(this._repository);

  final SkillRepository _repository;

  Future<Result<Unit, SkillFailure>> call(String name) {
    return _repository.deleteSkill(name);
  }
}
