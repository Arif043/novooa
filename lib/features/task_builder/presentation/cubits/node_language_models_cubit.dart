import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_models.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'node_language_models_state.dart';

class NodeLanguageModelsCubit extends Cubit<NodeLanguageModelsState> {
  NodeLanguageModelsCubit(
    this._authRepository,
    this._watchLanguageModels,
    this._getCurrentTeamId,
  ) : super(const NodeLanguageModelsState());

  final AuthRepository _authRepository;
  final WatchLanguageModels _watchLanguageModels;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<LanguageModel>>? _subscription;

  Future<void> load() async {
    if (_authRepository.currentUser() == null) {
      return _emitFailure('Du musst angemeldet sein.');
    }
    emit(const NodeLanguageModelsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchLanguageModels(teamId).listen(
      _emitModels,
      onError: (Object error, StackTrace stackTrace) {
        _logAndEmitFailure(
          LocaleKeys.ui_language_models_load_failed.tr(),
          error,
          stackTrace,
        );
      },
    );
  }

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      _logAndEmitFailure(
        LocaleKeys.ui_team_load_failed.tr(),
        error,
        stackTrace,
      );
      return null;
    }
  }

  void _emitModels(List<LanguageModel> models) {
    if (isClosed) return;
    emit(
      NodeLanguageModelsState(
        status: NodeLanguageModelsStatus.ready,
        models: models,
      ),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(
      NodeLanguageModelsState(
        status: NodeLanguageModelsStatus.failure,
        message: message,
      ),
    );
  }

  void _logAndEmitFailure(String message, Object error, StackTrace stackTrace) {
    logException(
      message: message,
      error: error,
      stackTrace: stackTrace,
      name: 'node_language_models',
    );
    _emitFailure(message);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
