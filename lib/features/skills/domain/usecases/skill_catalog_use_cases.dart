import 'package:multiple_result/multiple_result.dart';

import '../entities/skill_catalog.dart';
import '../entities/skill_failure.dart';
import '../repositories/skill_catalog_repository.dart';

class IsSkillCatalogAvailable {
  const IsSkillCatalogAvailable(this._repository);

  final SkillCatalogRepository _repository;

  Future<bool> call() => _repository.isAvailable();
}

class SearchSkillCatalog {
  const SearchSkillCatalog(this._repository);

  final SkillCatalogRepository _repository;

  Future<Result<List<CatalogSkill>, SkillFailure>> call(String query) =>
      _repository.search(query);
}

class BrowseSkillCatalog {
  const BrowseSkillCatalog(this._repository);

  final SkillCatalogRepository _repository;

  Future<Result<CatalogPage, SkillFailure>> call(CatalogView view, int page) =>
      _repository.browse(view, page);
}

class LoadSkillAudits {
  const LoadSkillAudits(this._repository);

  final SkillCatalogRepository _repository;

  Future<Result<List<CatalogAudit>, SkillFailure>> call(String skillId) =>
      _repository.audits(skillId);
}
