import '../../../files/domain/entities/team_id.dart';
import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_draft.dart';
import '../../domain/repositories/language_model_repository.dart';

class LocalLanguageModelRepository implements LanguageModelRepository {
  const LocalLanguageModelRepository();

  @override
  Future<void> saveLanguageModel(LanguageModelDraft draft) {
    throw UnsupportedError(
      'Sprachmodelle werden in der lokalen Runtime noch nicht verwaltet.',
    );
  }

  @override
  Stream<List<LanguageModel>> watchLanguageModels(TeamId teamId) {
    return Stream.value(const []);
  }
}
