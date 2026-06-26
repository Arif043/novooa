import '../../domain/entities/ai_model_settings.dart';
import '../../domain/entities/ai_provider.dart';
import '../../../user/domain/entities/user_profile.dart';

enum SettingsLoadStatus { loading, ready, failure }

class SettingsState {
  const SettingsState({
    this.loadStatus = SettingsLoadStatus.loading,
    this.profile,
    this.aiModelSettings,
    this.displayNameInput = '',
    this.apiKeyInput = '',
    this.selectedProvider = AiProvider.googleAi,
    this.isSavingProfile = false,
    this.isSavingAiModel = false,
    this.message,
  });

  final SettingsLoadStatus loadStatus;
  final UserProfile? profile;
  final AiModelSettings? aiModelSettings;
  final String displayNameInput;
  final String apiKeyInput;
  final AiProvider selectedProvider;
  final bool isSavingProfile;
  final bool isSavingAiModel;
  final String? message;

  bool get isReady => loadStatus == SettingsLoadStatus.ready;

  SettingsState copyWith({
    SettingsLoadStatus? loadStatus,
    UserProfile? profile,
    AiModelSettings? aiModelSettings,
    String? displayNameInput,
    String? apiKeyInput,
    AiProvider? selectedProvider,
    bool? isSavingProfile,
    bool? isSavingAiModel,
    String? message,
  }) {
    return SettingsState(
      loadStatus: loadStatus ?? this.loadStatus,
      profile: profile ?? this.profile,
      aiModelSettings: aiModelSettings ?? this.aiModelSettings,
      displayNameInput: displayNameInput ?? this.displayNameInput,
      apiKeyInput: apiKeyInput ?? this.apiKeyInput,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      isSavingAiModel: isSavingAiModel ?? this.isSavingAiModel,
      message: message,
    );
  }
}
