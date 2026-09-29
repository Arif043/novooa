import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_defaults.dart';

enum LanguageModelDefaultsStatus { loading, ready, failure }

class LanguageModelDefaultsState {
  const LanguageModelDefaultsState({
    this.status = LanguageModelDefaultsStatus.loading,
    this.models = const [],
    this.defaults = const LanguageModelDefaults.empty(),
    this.isSavingBlockDefault = false,
    this.isSavingAssistantDefault = false,
    this.message,
  });

  final LanguageModelDefaultsStatus status;
  final List<LanguageModel> models;
  final LanguageModelDefaults defaults;
  final bool isSavingBlockDefault;
  final bool isSavingAssistantDefault;
  final String? message;

  LanguageModelDefaultsState copyWith({
    LanguageModelDefaultsStatus? status,
    List<LanguageModel>? models,
    LanguageModelDefaults? defaults,
    bool? isSavingBlockDefault,
    bool? isSavingAssistantDefault,
    String? message,
  }) {
    return LanguageModelDefaultsState(
      status: status ?? this.status,
      models: models ?? this.models,
      defaults: defaults ?? this.defaults,
      isSavingBlockDefault: isSavingBlockDefault ?? this.isSavingBlockDefault,
      isSavingAssistantDefault:
          isSavingAssistantDefault ?? this.isSavingAssistantDefault,
      message: message,
    );
  }
}
