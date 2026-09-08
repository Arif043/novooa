import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';
import 'package:syscat2/features/language_models/domain/usecases/save_language_model.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'language_models_settings_state.dart';

class LanguageModelsSettingsCubit extends Cubit<LanguageModelsSettingsState> {
  LanguageModelsSettingsCubit(
    this._authRepository,
    this._watchLanguageModels,
    this._saveLanguageModel,
    this._getCurrentTeamId,
  ) : super(const LanguageModelsSettingsState());

  final AuthRepository _authRepository;
  final WatchLanguageModels _watchLanguageModels;
  final SaveLanguageModel _saveLanguageModel;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<LanguageModel>>? _subscription;

  Future<void> load() async {
    if (_authRepository.currentUser() == null) {
      return _emitFailure('Du musst angemeldet sein.');
    }
    emit(const LanguageModelsSettingsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchLanguageModels(teamId).listen(
      (models) => emit(
        state.copyWith(
          status: LanguageModelsSettingsStatus.ready,
          models: models,
        ),
      ),
      onError: (_) =>
          _emitFailure('Sprachmodelle konnten nicht geladen werden.'),
    );
  }

  void updateProvider(LanguageModelProvider value) {
    emit(state.copyWith(provider: value));
  }

  void updateConnectionName(String value) =>
      emit(state.copyWith(connectionName: value));
  void updateBaseUrl(String value) => emit(state.copyWith(baseUrl: value));
  void updateName(String value) => emit(state.copyWith(name: value));
  void updateModelId(String value) => emit(state.copyWith(modelId: value));
  void updateApiKey(String value) => emit(state.copyWith(apiKey: value));

  Future<void> save() async {
    final draft = _draftOrNull();
    if (draft == null) {
      return _emitMessage('Bitte fülle alle erforderlichen Felder aus.');
    }
    emit(state.copyWith(isSaving: true));
    try {
      await _saveLanguageModel(draft);
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          connectionName: '',
          baseUrl: '',
          name: '',
          modelId: '',
          apiKey: '',
          isSaving: false,
          message: 'Sprachmodell verbunden.',
        ),
      );
    } catch (_) {
      _emitMessage('Sprachmodell konnte nicht gespeichert werden.');
    }
  }

  LanguageModelDraft? _draftOrNull() {
    final requiresBaseUrl =
        state.provider == LanguageModelProvider.openAiCompatible;
    if (state.connectionName.trim().isEmpty ||
        state.name.trim().isEmpty ||
        state.modelId.trim().isEmpty ||
        state.apiKey.trim().length < 8 ||
        (requiresBaseUrl && state.baseUrl.trim().isEmpty)) {
      return null;
    }
    return LanguageModelDraft(
      connectionName: state.connectionName.trim(),
      provider: state.provider,
      baseUrl: state.baseUrl.trim(),
      name: state.name.trim(),
      modelId: state.modelId.trim(),
      apiKey: state.apiKey.trim(),
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (_) {
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: LanguageModelsSettingsStatus.failure,
        message: message,
      ),
    );
  }

  void _emitMessage(String message) {
    if (isClosed) return;
    emit(state.copyWith(isSaving: false, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
