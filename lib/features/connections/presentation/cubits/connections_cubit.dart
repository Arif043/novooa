import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/connection.dart';
import '../../domain/entities/connection_draft.dart';
import '../../domain/entities/connection_failure.dart';
import '../../domain/entities/connection_test_result.dart';
import '../../domain/usecases/connection_use_cases.dart';
import 'connections_state.dart';

/// Zeigt die gespeicherten Verbindungen und legt sie an, ändert, löscht und
/// testet sie. Änderungen meldet die Runtime per Realtime-Kanal.
class ConnectionsCubit extends Cubit<ConnectionsState> {
  ConnectionsCubit(
    this._watchConnections,
    this._createConnection,
    this._updateConnection,
    this._deleteConnection,
    this._testConnection,
    this._getCurrentTeamId,
  ) : super(const ConnectionsState());

  final WatchConnections _watchConnections;
  final CreateConnection _createConnection;
  final UpdateConnection _updateConnection;
  final DeleteConnection _deleteConnection;
  final TestConnection _testConnection;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<Connection>>? _subscription;

  Future<void> load() async {
    emit(const ConnectionsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchConnections(teamId).listen(
      _emitConnections,
      onError: (Object error, StackTrace stackTrace) {
        logException(
          message: 'Verbindungen konnten nicht geladen werden.',
          error: error,
          stackTrace: stackTrace,
          name: 'connections',
        );
        _emitFailure(ConnectionFailure.loadFailed.message);
      },
    );
  }

  /// Legt an (ohne [id]) oder ändert. Gibt die Fehlermeldung zurück, damit der
  /// Editor sie neben dem Formular zeigen kann; `null` heißt gespeichert.
  Future<String?> save(ConnectionDraft draft, {String? id}) async {
    final result = id == null
        ? await _createConnection(draft)
        : await _updateConnection(id, draft);
    if (isClosed) return null;
    return result.when((connection) {
      emit(state.copyWith(message: 'Verbindung „${connection.name}“ gespeichert.'));
      return null;
    }, (failure) => failure.message);
  }

  Future<void> delete(String id) async {
    final name = state.connections
        .where((connection) => connection.id == id)
        .map((connection) => connection.name)
        .firstOrNull;
    final result = await _deleteConnection(id);
    if (isClosed) return;
    result.when(
      (_) => emit(
        state.copyWith(message: 'Verbindung „${name ?? id}“ gelöscht.'),
      ),
      (failure) => emit(state.copyWith(message: failure.message)),
    );
  }

  /// Getestet wird der gespeicherte Stand. Ein Fehler beim Testen ist ein
  /// Ergebnis (`ok: false`), keine Ausnahme.
  Future<ConnectionTestResult> test(String id, {String path = ''}) async {
    final result = await _testConnection(id, path: path);
    return result.when(
      (tested) => tested,
      (failure) => ConnectionTestResult(ok: false, message: failure.message),
    );
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      logException(
        message: 'Team konnte nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'connections',
      );
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  void _emitConnections(List<Connection> connections) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: ConnectionsStatus.ready,
        connections: connections,
      ),
    );
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: ConnectionsStatus.failure, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
