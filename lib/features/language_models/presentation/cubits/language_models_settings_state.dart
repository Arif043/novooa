import '../../domain/entities/language_model.dart';
import '../../domain/entities/language_model_provider.dart';

enum LanguageModelsSettingsStatus { loading, ready, failure }

class LanguageModelsSettingsState {
  const LanguageModelsSettingsState({
    this.status = LanguageModelsSettingsStatus.loading,
    this.models = const [],
    this.provider = LanguageModelProvider.googleAi,
    this.baseUrl = '',
    this.apiKey = '',
    this.isConnecting = false,
    this.message,
  });

  final LanguageModelsSettingsStatus status;
  final List<LanguageModel> models;
  final LanguageModelProvider provider;
  final String baseUrl;
  final String apiKey;
  final bool isConnecting;
  final String? message;

  LanguageModelsSettingsState copyWith({
    LanguageModelsSettingsStatus? status,
    List<LanguageModel>? models,
    LanguageModelProvider? provider,
    String? baseUrl,
    String? apiKey,
    bool? isConnecting,
    String? message,
  }) {
    return LanguageModelsSettingsState(
      status: status ?? this.status,
      models: models ?? this.models,
      provider: provider ?? this.provider,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      isConnecting: isConnecting ?? this.isConnecting,
      message: message,
    );
  }
}
