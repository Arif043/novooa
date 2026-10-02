import 'package:multiple_result/multiple_result.dart';

import '../entities/skill_catalog.dart';
import '../entities/skill_failure.dart';

/// Katalog (skills.sh) zum Suchen und Durchstöbern.
abstract class SkillCatalogRepository {
  /// `false`, wenn kein Zugang zum Katalog eingerichtet ist.
  Future<bool> isAvailable();

  Future<Result<List<CatalogSkill>, SkillFailure>> search(String query);

  Future<Result<CatalogPage, SkillFailure>> browse(CatalogView view, int page);

  Future<Result<List<CatalogAudit>, SkillFailure>> audits(String skillId);
}
