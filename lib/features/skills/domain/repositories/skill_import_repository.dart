import 'package:multiple_result/multiple_result.dart';

import '../entities/skill.dart';
import '../entities/skill_failure.dart';
import '../entities/skill_import.dart';

abstract class SkillImportRepository {
  /// Liest die Quelle und liefert die gefundenen Skills, ohne etwas zu speichern.
  Future<Result<SkillImportPreview, SkillFailure>> preview(
    SkillImportSource source,
  );

  /// Übernimmt die ausgewählten Skills einer Vorschau in den Skills-Ordner.
  Future<Result<List<Skill>, SkillFailure>> commit(
    String importId,
    List<String> names,
  );
}
