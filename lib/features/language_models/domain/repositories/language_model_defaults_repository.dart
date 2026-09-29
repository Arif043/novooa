import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model_defaults.dart';

abstract interface class LanguageModelDefaultsRepository {
  Stream<LanguageModelDefaults> watchLanguageModelDefaults(TeamId teamId);

  Future<void> saveLanguageModelDefaults(
    TeamId teamId,
    LanguageModelDefaults defaults,
  );
}
