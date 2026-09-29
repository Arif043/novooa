import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model_defaults.dart';
import '../repositories/language_model_defaults_repository.dart';

class WatchLanguageModelDefaults {
  const WatchLanguageModelDefaults(this._repository);

  final LanguageModelDefaultsRepository _repository;

  Stream<LanguageModelDefaults> call(TeamId teamId) {
    return _repository.watchLanguageModelDefaults(teamId);
  }
}
