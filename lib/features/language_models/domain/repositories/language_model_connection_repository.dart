import '../entities/language_model_connection_draft.dart';

abstract interface class LanguageModelConnectionRepository {
  Future<void> connectLanguageModels(LanguageModelConnectionDraft draft);
}
