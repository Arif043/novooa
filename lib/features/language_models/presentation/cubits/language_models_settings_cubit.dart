import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection_draft.dart';
import 'package:syscat2/features/language_models/domain/usecases/connect_language_models.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'language_models_settings_state.dart';

class LanguageModelsSettingsCubit extends Cubit<LanguageModelsSettingsState> {
  LanguageModelsSettingsCubit(
    this._authRepository,
    this._watchLanguageModels,
    this._getCurrentTeamId,
    this._connectLanguageModels,
  ) : super(const LanguageModelsSettingsState());

  final AuthRepository _authRepository;
  final WatchLanguageModels _watchLanguageModels;
  final GetCurrentTeamId _getCurrentTeamId;
  final ConnectLanguageModels _connectLanguageModels;
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
    emit(
      state.copyWith(
        provider: value,
        baseUrl:
            value.defaultBaseUrl ??
            (value == LanguageModelProvider.ollama ? _ollamaBaseUrl : ''),
      ),
    );
  }

  void updateBaseUrl(String value) => emit(state.copyWith(baseUrl: value));
  void updateApiKey(String value) => emit(state.copyWith(apiKey: value));

  Future<void> connect() async {
    final draft = _connectionDraftOrNull();
    if (draft == null) {
      return _emitMessage('Bitte gib einen gültigen Anbieterzugang ein.');
    }
    emit(state.copyWith(isConnecting: true));
    try {
      await _connectLanguageModels(draft);
      if (!isClosed) {
        emit(
          state.copyWith(
            apiKey: '',
            isConnecting: false,
            message: 'Modelle wurden verbunden.',
          ),
        );
      }
    } catch (_) {
      _emitMessage('Modelle konnten nicht vom Anbieter geladen werden.');
    }
  }

  LanguageModelConnectionDraft? _connectionDraftOrNull() {
    final hasEndpoint =
        !state.provider.requiresCustomBaseUrl ||
        state.baseUrl.trim().isNotEmpty;
    if (!hasEndpoint || (_requiresApiKey() && state.apiKey.trim().length < 8)) {
      return null;
    }
    return LanguageModelConnectionDraft(
      provider: state.provider,
      baseUrl: state.baseUrl.trim(),
      apiKey: state.apiKey.trim(),
    );
  }

  /// Lokale Endpunkte wie Ollama über `host.docker.internal` brauchen
  /// keinen Schlüssel.
  bool _requiresApiKey() {
    if (state.provider == LanguageModelProvider.ollama) return false;
    return Uri.tryParse(state.baseUrl)?.host != 'host.docker.internal';
  }

  static const _ollamaBaseUrl = 'http://host.docker.internal:11434/v1';

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
    emit(state.copyWith(isConnecting: false, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
