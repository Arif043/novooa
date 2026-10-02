import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/usecases/save_language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_model_defaults.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'language_model_defaults_state.dart';

/// Eigener Cubit statt Erweiterung von `LanguageModelsSettingsCubit` — andere
/// Zuständigkeit (Vorgabe-Zeiger statt Verbinden neuer Modelle), Muster wie
/// `NodeLanguageModelsCubit` neben `LanguageModelsSettingsCubit`. Kombiniert
/// die Liste verbundener Modelle (Auswahlmöglichkeiten) mit den gespeicherten
/// Vorgaben (aktuelle Wahl) über zwei separate Abonnements, da es in diesem
/// Projekt kein `combineLatest` gibt.
class LanguageModelDefaultsCubit extends Cubit<LanguageModelDefaultsState> {
  LanguageModelDefaultsCubit(
    this._authRepository,
    this._watchLanguageModels,
    this._watchLanguageModelDefaults,
    this._saveLanguageModelDefaults,
    this._getCurrentTeamId,
  ) : super(const LanguageModelDefaultsState());

  final AuthRepository _authRepository;
  final WatchLanguageModels _watchLanguageModels;
  final WatchLanguageModelDefaults _watchLanguageModelDefaults;
  final SaveLanguageModelDefaults _saveLanguageModelDefaults;
  final GetCurrentTeamId _getCurrentTeamId;

  StreamSubscription<List<LanguageModel>>? _modelsSubscription;
  StreamSubscription<LanguageModelDefaults>? _defaultsSubscription;
  TeamId? _teamId;

  Future<void> load() async {
    if (_authRepository.currentUser() == null) {
      return _emitFailure('Du musst angemeldet sein.');
    }
    emit(const LanguageModelDefaultsState());
    await _modelsSubscription?.cancel();
    await _defaultsSubscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _teamId = teamId;
    _modelsSubscription = _watchLanguageModels(teamId).listen(
      (models) => emit(
        state.copyWith(
          status: LanguageModelDefaultsStatus.ready,
          models: models,
        ),
      ),
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          'Sprachmodelle konnten nicht geladen werden.',
          error,
          stackTrace,
        );
      },
    );
    _defaultsSubscription = _watchLanguageModelDefaults(teamId).listen(
      (defaults) => emit(
        state.copyWith(
          status: LanguageModelDefaultsStatus.ready,
          defaults: defaults,
        ),
      ),
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          'Vorgaben konnten nicht geladen werden.',
          error,
          stackTrace,
        );
      },
    );
  }

  Future<void> saveBlockDefault(String? modelId) {
    return _saveDefaults(
      LanguageModelDefaults(
        blockModelId: modelId,
        assistantModelId: state.defaults.assistantModelId,
      ),
      isSavingBlockDefault: true,
    );
  }

  Future<void> saveAssistantDefault(String? modelId) {
    return _saveDefaults(
      LanguageModelDefaults(
        blockModelId: state.defaults.blockModelId,
        assistantModelId: modelId,
      ),
      isSavingAssistantDefault: true,
    );
  }

  Future<void> _saveDefaults(
    LanguageModelDefaults defaults, {
    bool isSavingBlockDefault = false,
    bool isSavingAssistantDefault = false,
  }) async {
    final teamId = _teamId;
    if (teamId == null) return;
    emit(
      state.copyWith(
        isSavingBlockDefault: isSavingBlockDefault,
        isSavingAssistantDefault: isSavingAssistantDefault,
      ),
    );
    try {
      await _saveLanguageModelDefaults(teamId, defaults);
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        'Vorgabe konnte nicht gespeichert werden.',
        error,
        stackTrace,
      );
    } finally {
      if (!isClosed) {
        emit(
          state.copyWith(
            isSavingBlockDefault: false,
            isSavingAssistantDefault: false,
          ),
        );
      }
    }
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        'Team konnte nicht geladen werden.',
        error,
        stackTrace,
      );
      return null;
    }
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: LanguageModelDefaultsStatus.failure,
        message: message,
      ),
    );
  }

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'language_model_defaults',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() async {
    await _modelsSubscription?.cancel();
    await _defaultsSubscription?.cancel();
    return super.close();
  }
}
