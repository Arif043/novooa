import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_draft.dart';

enum LanguageModelsSettingsStatus { loading, ready, failure }

class LanguageModelsSettingsState {
  const LanguageModelsSettingsState({
    this.status = LanguageModelsSettingsStatus.loading,
    this.models = const [],
    this.provider = LanguageModelProvider.googleAi,
    this.connectionName = '',
    this.baseUrl = '',
    this.name = '',
    this.modelId = '',
    this.apiKey = '',
    this.isSaving = false,
    this.message,
  });

  final LanguageModelsSettingsStatus status;
  final List<LanguageModel> models;
  final LanguageModelProvider provider;
  final String connectionName;
  final String baseUrl;
  final String name;
  final String modelId;
  final String apiKey;
  final bool isSaving;
  final String? message;

  LanguageModelsSettingsState copyWith({
    LanguageModelsSettingsStatus? status,
    List<LanguageModel>? models,
    LanguageModelProvider? provider,
    String? connectionName,
    String? baseUrl,
    String? name,
    String? modelId,
    String? apiKey,
    bool? isSaving,
    String? message,
  }) {
    return LanguageModelsSettingsState(
      status: status ?? this.status,
      models: models ?? this.models,
      provider: provider ?? this.provider,
      connectionName: connectionName ?? this.connectionName,
      baseUrl: baseUrl ?? this.baseUrl,
      name: name ?? this.name,
      modelId: modelId ?? this.modelId,
      apiKey: apiKey ?? this.apiKey,
      isSaving: isSaving ?? this.isSaving,
      message: message,
    );
  }
}
