import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model_defaults.dart';
import '../repositories/language_model_defaults_repository.dart';

class SaveLanguageModelDefaults {
  const SaveLanguageModelDefaults(this._repository);

  final LanguageModelDefaultsRepository _repository;

  Future<void> call(TeamId teamId, LanguageModelDefaults defaults) {
    return _repository.saveLanguageModelDefaults(teamId, defaults);
  }
}
