import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../../user/domain/entities/user_profile.dart';
import '../../../user/domain/usecases/ensure_user_profile.dart';
import '../../../user/domain/usecases/get_current_user_profile.dart';
import '../../domain/entities/ai_model_settings.dart';
import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/api_key.dart';
import '../../domain/entities/settings_failure.dart';
import '../../domain/usecases/save_ai_provider_settings.dart';
import '../../domain/usecases/watch_ai_model_settings.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetCurrentUserProfile getCurrentUserProfile,
    required EnsureUserProfile ensureUserProfile,
    required WatchAiModelSettings watchAiModelSettings,
    required SaveAiProviderSettings saveAiProviderSettings,
  }) : _getCurrentUserProfile = getCurrentUserProfile,
       _ensureUserProfile = ensureUserProfile,
       _watchAiModelSettings = watchAiModelSettings,
       _saveAiProviderSettings = saveAiProviderSettings,
       super(const SettingsState());

  final GetCurrentUserProfile _getCurrentUserProfile;
  final EnsureUserProfile _ensureUserProfile;
  final WatchAiModelSettings _watchAiModelSettings;
  final SaveAiProviderSettings _saveAiProviderSettings;
  StreamSubscription<Result<AiModelSettings, SettingsFailure>>?
  _settingsSubscription;

  Future<void> load() async {
    emit(const SettingsState());
    final userProfileOrFailure = await _getCurrentUserProfile();
    if (isClosed) return;
    await userProfileOrFailure.when(_watchAiSettings, (failure) async {
      _emitFailure(failure.message);
    });
  }

  void updateDisplayName(String value) {
    emit(state.copyWith(displayNameInput: value));
  }

  void updateProvider(AiProvider provider) {
    emit(state.copyWith(selectedProvider: provider));
  }

  void updateApiKey(String value) {
    emit(state.copyWith(apiKeyInput: value));
  }

  Future<void> saveProfile() async {
    final profile = state.profile;
    if (profile == null) return;
    if (state.displayNameInput.trim().length < 2) {
      return _emitMessage(SettingsFailureKind.invalidDisplayName.message);
    }
    emit(state.copyWith(isSavingProfile: true));
    final userProfileOrFailure = await _ensureUserProfile(
      EnsureUserProfileParams(
        id: profile.id,
        email: profile.email,
        displayName: state.displayNameInput,
      ),
    );
    if (isClosed) return;
    userProfileOrFailure.when(
      (updatedProfile) => emit(
        state.copyWith(
          profile: updatedProfile,
          displayNameInput: updatedProfile.displayName,
          isSavingProfile: false,
          message: 'Profil gespeichert.',
        ),
      ),
      (failure) => _emitMessage(failure.message),
    );
  }

  Future<void> saveAiModelSettings() async {
    final profile = state.profile;
    final apiKey = ApiKey.tryCreate(state.apiKeyInput);
    if (profile == null) return;
    if (apiKey == null) {
      return _emitMessage(SettingsFailureKind.invalidApiKey.message);
    }
    emit(state.copyWith(isSavingAiModel: true));
    final settingsOrFailure = await _saveAiProviderSettings(
      SaveAiProviderSettingsParams(
        userId: profile.id,
        provider: state.selectedProvider,
        apiKey: apiKey,
      ),
    );
    if (isClosed) return;
    settingsOrFailure.when(
      (settings) => emit(
        state.copyWith(
          aiModelSettings: settings,
          apiKeyInput: '',
          isSavingAiModel: false,
          message: 'Sprachmodell gespeichert.',
        ),
      ),
      (failure) => _emitMessage(failure.message),
    );
  }

  Future<void> _watchAiSettings(UserProfile profile) async {
    _settingsSubscription?.cancel();
    _settingsSubscription = _watchAiModelSettings(profile.id).listen(
      (settingsOrFailure) => _emitSettings(profile, settingsOrFailure),
      onError: (_) => _emitFailure(SettingsFailureKind.loadFailed.message),
    );
  }

  void _emitSettings(
    UserProfile profile,
    Result<AiModelSettings, SettingsFailure> settingsOrFailure,
  ) {
    if (isClosed) return;
    settingsOrFailure.when(
      (settings) => emit(
        SettingsState(
          loadStatus: SettingsLoadStatus.ready,
          profile: profile,
          aiModelSettings: settings,
          displayNameInput: profile.displayName,
          selectedProvider: settings.provider,
        ),
      ),
      (failure) => _emitFailure(failure.message),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      SettingsState(loadStatus: SettingsLoadStatus.failure, message: message),
    );
  }

  void _emitMessage(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        isSavingProfile: false,
        isSavingAiModel: false,
        message: message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _settingsSubscription?.cancel();
    return super.close();
  }
}

extension on SettingsFailureKind {
  String get message => SettingsFailure(this).message;
}
