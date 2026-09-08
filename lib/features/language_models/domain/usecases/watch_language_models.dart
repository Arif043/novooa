import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model.dart';
import '../repositories/language_model_repository.dart';

class WatchLanguageModels {
  const WatchLanguageModels(this._repository);

  final LanguageModelRepository _repository;

  Stream<List<LanguageModel>> call(TeamId teamId) {
    return _repository.watchLanguageModels(teamId);
  }
}
