import 'package:bloc/bloc.dart';

import '../../domain/entities/runtime_session.dart';
import '../../domain/entities/runtime_session_failure.dart';
import '../../domain/usecases/load_runtime_sessions.dart';
import '../../domain/usecases/revoke_other_runtime_sessions.dart';
import '../../domain/usecases/revoke_runtime_session.dart';
import 'runtime_sessions_state.dart';

/// Angemeldete Geräte des eigenen Kontos: ansehen, einzeln oder alle anderen
/// abmelden. Nach dem Abmelden wird die Liste lokal angepasst, ohne erneutes
/// Laden.
class RuntimeSessionsCubit extends Cubit<RuntimeSessionsState> {
  RuntimeSessionsCubit(
    this._loadSessions,
    this._revokeSession,
    this._revokeOtherSessions,
  ) : super(const RuntimeSessionsLoading());

  final LoadRuntimeSessions _loadSessions;
  final RevokeRuntimeSession _revokeSession;
  final RevokeOtherRuntimeSessions _revokeOtherSessions;

  Future<void> load() async {
    emit(const RuntimeSessionsLoading());
    final sessionsOrFailure = await _loadSessions();
    if (isClosed) return;
    emit(
      sessionsOrFailure.when(
        RuntimeSessionsLoaded.new,
        RuntimeSessionsLoadFailed.new,
      ),
    );
  }

  Future<void> revoke(RuntimeSession session) async {
    final loaded = _idleLoaded;
    if (loaded == null || session.isCurrent) return;
    emit(loaded.copyWith(revoking: RevokingSession(session.id)));
    final revokedOrFailure = await _revokeSession(session);
    if (isClosed) return;
    revokedOrFailure.when(
      (_) => emit(
        loaded.copyWith(
          sessions: _without(loaded, session.id),
          revoking: const RevokingNothing(),
          notice: const SessionRevokedNotice(),
        ),
      ),
      (failure) => _showFailure(loaded, failure, removedId: session.id),
    );
  }

  Future<void> revokeOthers() async {
    final loaded = _idleLoaded;
    if (loaded == null) return;
    emit(loaded.copyWith(revoking: const RevokingOthers()));
    final countOrFailure = await _revokeOtherSessions();
    if (isClosed) return;
    countOrFailure.when(
      (count) => emit(
        loaded.copyWith(
          sessions: [...loaded.sessions.where((s) => s.isCurrent)],
          revoking: const RevokingNothing(),
          notice: OthersRevokedNotice(count),
        ),
      ),
      (failure) => _showFailure(loaded, failure),
    );
  }

  RuntimeSessionsLoaded? get _idleLoaded => switch (state) {
    final RuntimeSessionsLoaded loaded when !loaded.isBusy => loaded,
    _ => null,
  };

  List<RuntimeSession> _without(
    RuntimeSessionsLoaded loaded,
    RuntimeSessionId id,
  ) => [...loaded.sessions.where((session) => session.id != id)];

  /// Gibt es die Sitzung nicht mehr, verschwindet sie trotzdem aus der Liste.
  void _showFailure(
    RuntimeSessionsLoaded loaded,
    RuntimeSessionFailure failure, {
    RuntimeSessionId? removedId,
  }) {
    final isGone = failure.kind == RuntimeSessionFailureKind.notFound;
    emit(
      loaded.copyWith(
        sessions: isGone && removedId != null
            ? _without(loaded, removedId)
            : null,
        revoking: const RevokingNothing(),
        notice: RevokeFailedNotice(failure),
      ),
    );
  }
}
