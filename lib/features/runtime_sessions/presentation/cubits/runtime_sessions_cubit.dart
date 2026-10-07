import 'package:bloc/bloc.dart';

import '../../domain/usecases/revoke_other_runtime_sessions.dart';
import 'runtime_sessions_state.dart';

class RuntimeSessionsCubit extends Cubit<RuntimeSessionsState> {
  RuntimeSessionsCubit(this._revokeOtherSessions)
    : super(const RuntimeSessionsIdle());

  final RevokeOtherRuntimeSessions _revokeOtherSessions;

  Future<void> revokeOtherSessions() async {
    if (state is RuntimeSessionsRevoking) return;
    emit(const RuntimeSessionsRevoking());
    final revokedOrFailure = await _revokeOtherSessions();
    if (isClosed) return;
    revokedOrFailure.when(
      (revoked) => emit(RuntimeSessionsRevoked(revoked.count)),
      (failure) => emit(RuntimeSessionsFailed(failure.message)),
    );
  }
}
