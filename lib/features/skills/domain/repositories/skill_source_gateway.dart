import 'package:multiple_result/multiple_result.dart';

import '../entities/skill_failure.dart';
import '../entities/skill_import.dart';

/// Lässt den Nutzer eine Importquelle auf dem Gerät wählen (ZIP-Datei oder Ordner).
abstract interface class SkillSourceGateway {
  /// Ordner lassen sich nur auf dem Desktop wählen und lesen.
  bool get canPickFolder;

  /// [SkillFailure.cancelled], wenn der Nutzer die Auswahl abbricht.
  Future<Result<SkillImportSource, SkillFailure>> pickArchive();

  Future<Result<SkillImportSource, SkillFailure>> pickFolder();
}
