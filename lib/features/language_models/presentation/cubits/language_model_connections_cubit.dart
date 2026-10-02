import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/usecases/remove_language_model_connection.dart';
import 'package:syscat2/features/language_models/domain/usecases/watch_language_model_connections.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import 'language_model_connections_state.dart';

/// Verwaltet ausschließlich die verbundenen Anbieter (Standalone) — getrennt
/// von [LanguageModelsSettingsCubit], das die Modell-Liste sowie das
/// Verbinden/Speichern-Formular verantwortet (SRP: unterschiedliche Gründe
/// für Änderungen).
class LanguageModelConnectionsCubit
    extends Cubit<LanguageModelConnectionsState> {
  LanguageModelConnectionsCubit(
    this._authRepository,
    this._watchLanguageModelConnections,
    this._removeLanguageModelConnection,
    this._getCurrentTeamId,
  ) : super(const LanguageModelConnectionsState());

  final AuthRepository _authRepository;
  final WatchLanguageModelConnections _watchLanguageModelConnections;
  final RemoveLanguageModelConnection _removeLanguageModelConnection;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<LanguageModelConnection>>? _subscription;

  Future<void> load() async {
    if (_authRepository.currentUser() == null) {
      return _emitFailure('Du musst angemeldet sein.');
    }
    emit(const LanguageModelConnectionsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchLanguageModelConnections(teamId).listen(
      (connections) => emit(
        state.copyWith(
          status: LanguageModelConnectionsStatus.ready,
          connections: connections,
        ),
      ),
      onError: (_) =>
          _emitFailure('Anbieter-Verbindungen konnten nicht geladen werden.'),
    );
  }

  Future<void> removeConnection(String connectionId) async {
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    try {
      await _removeLanguageModelConnection(teamId, connectionId);
      if (!isClosed) emit(state.copyWith(message: 'Verbindung entfernt.'));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(message: 'Verbindung konnte nicht entfernt werden.'),
        );
      }
    }
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
        status: LanguageModelConnectionsStatus.failure,
        message: message,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
