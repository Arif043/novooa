import 'package:multiple_result/multiple_result.dart';

import '../entities/skill.dart';
import '../entities/skill_failure.dart';
import '../entities/skill_import.dart';
import '../repositories/skill_import_repository.dart';

class PreviewSkillImport {
  const PreviewSkillImport(this._repository);

  final SkillImportRepository _repository;

  Future<Result<SkillImportPreview, SkillFailure>> call(
    SkillImportSource source,
  ) => _repository.preview(source);
}

class CommitSkillImport {
  const CommitSkillImport(this._repository);

  final SkillImportRepository _repository;

  Future<Result<List<Skill>, SkillFailure>> call(
    String importId,
    List<String> names,
  ) => _repository.commit(importId, names);
}
