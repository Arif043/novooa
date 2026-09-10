import '../entities/language_model_connection_draft.dart';
import '../repositories/language_model_connection_repository.dart';

class ConnectLanguageModels {
  const ConnectLanguageModels(this._repository);

  final LanguageModelConnectionRepository _repository;

  Future<void> call(LanguageModelConnectionDraft draft) {
    return _repository.connectLanguageModels(draft);
  }
}
