import '../../../files/domain/entities/team_id.dart';
import '../entities/language_model.dart';
import '../entities/language_model_draft.dart';

abstract interface class LanguageModelRepository {
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId);

  Future<void> saveLanguageModel(LanguageModelDraft draft);
}
