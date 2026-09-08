import '../entities/language_model_draft.dart';
import '../repositories/language_model_repository.dart';

class SaveLanguageModel {
  const SaveLanguageModel(this._repository);

  final LanguageModelRepository _repository;

  Future<void> call(LanguageModelDraft draft) {
    return _repository.saveLanguageModel(draft);
  }
}
