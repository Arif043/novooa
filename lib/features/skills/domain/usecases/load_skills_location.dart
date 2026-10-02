import 'package:multiple_result/multiple_result.dart';

import '../entities/skill_failure.dart';
import '../repositories/skill_repository.dart';

class LoadSkillsLocation {
  const LoadSkillsLocation(this._repository);

  final SkillRepository _repository;

  Future<Result<String, SkillFailure>> call() => _repository.loadLocation();
}
