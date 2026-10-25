import '../../domain/entities/runtime_session.dart';
import '../../domain/entities/runtime_session_failure.dart';

sealed class RuntimeSessionsState {
  const RuntimeSessionsState();
}

final class RuntimeSessionsLoading extends RuntimeSessionsState {
  const RuntimeSessionsLoading();
}

final class RuntimeSessionsLoadFailed extends RuntimeSessionsState {
  const RuntimeSessionsLoadFailed(this.failure);

  final RuntimeSessionFailure failure;
}

final class RuntimeSessionsLoaded extends RuntimeSessionsState {
  const RuntimeSessionsLoaded(
    this.sessions, {
    this.revoking = const RevokingNothing(),
    this.notice,
  });

  final List<RuntimeSession> sessions;
  final RuntimeSessionsRevoking revoking;

  /// Einmalige Rückmeldung für eine Snackbar; jede Meldung ist ein neues
  /// Objekt, damit auch eine gleiche Meldung erneut erscheint.
  final RuntimeSessionsNotice? notice;

  bool get isBusy => revoking is! RevokingNothing;

  bool get hasOtherSessions => sessions.any((session) => !session.isCurrent);

  RuntimeSessionsLoaded copyWith({
    List<RuntimeSession>? sessions,
    RuntimeSessionsRevoking? revoking,
    RuntimeSessionsNotice? notice,
  }) => RuntimeSessionsLoaded(
    sessions ?? this.sessions,
    revoking: revoking ?? this.revoking,
    notice: notice,
  );
}

sealed class RuntimeSessionsRevoking {
  const RuntimeSessionsRevoking();
}

final class RevokingNothing extends RuntimeSessionsRevoking {
  const RevokingNothing();
}

final class RevokingSession extends RuntimeSessionsRevoking {
  const RevokingSession(this.id);

  final RuntimeSessionId id;
}

final class RevokingOthers extends RuntimeSessionsRevoking {
  const RevokingOthers();
}

sealed class RuntimeSessionsNotice {
  const RuntimeSessionsNotice();
}

final class SessionRevokedNotice extends RuntimeSessionsNotice {
  const SessionRevokedNotice();
}

final class OthersRevokedNotice extends RuntimeSessionsNotice {
  const OthersRevokedNotice(this.count);

  final int count;
}

final class RevokeFailedNotice extends RuntimeSessionsNotice {
  const RevokeFailedNotice(this.failure);

  final RuntimeSessionFailure failure;
}
