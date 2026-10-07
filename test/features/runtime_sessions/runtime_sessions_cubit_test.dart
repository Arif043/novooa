import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/revoked_sessions.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session_failure.dart';
import 'package:syscat2/features/runtime_sessions/domain/repositories/runtime_session_repository.dart';
import 'package:syscat2/features/runtime_sessions/domain/usecases/revoke_other_runtime_sessions.dart';
import 'package:syscat2/features/runtime_sessions/presentation/cubits/runtime_sessions_cubit.dart';
import 'package:syscat2/features/runtime_sessions/presentation/cubits/runtime_sessions_state.dart';

void main() {
  test('meldet die Zahl der abgemeldeten Geräte', () async {
    final cubit = _cubitWith(const Success(RevokedSessions(2)));
    final states = <RuntimeSessionsState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.revokeOtherSessions();

    expect(states.first, isA<RuntimeSessionsRevoking>());
    expect((cubit.state as RuntimeSessionsRevoked).count, 2);
    await subscription.cancel();
    await cubit.close();
  });

  test('meldet eine nicht erreichbare Runtime verständlich', () async {
    final cubit = _cubitWith(
      const Error(
        RuntimeSessionFailure(RuntimeSessionFailureKind.runtimeUnavailable),
      ),
    );

    await cubit.revokeOtherSessions();

    expect(
      (cubit.state as RuntimeSessionsFailed).message,
      contains('nicht erreichbar'),
    );
    await cubit.close();
  });

  test('startet keinen zweiten Widerruf, solange einer läuft', () async {
    final repository = _CountingRepository();
    final cubit = RuntimeSessionsCubit(RevokeOtherRuntimeSessions(repository));

    await Future.wait([
      cubit.revokeOtherSessions(),
      cubit.revokeOtherSessions(),
    ]);

    expect(repository.calls, 1);
    await cubit.close();
  });
}

RuntimeSessionsCubit _cubitWith(
  Result<RevokedSessions, RuntimeSessionFailure> result,
) {
  return RuntimeSessionsCubit(
    RevokeOtherRuntimeSessions(_FixedRepository(result)),
  );
}

class _FixedRepository implements RuntimeSessionRepository {
  const _FixedRepository(this.result);

  final Result<RevokedSessions, RuntimeSessionFailure> result;

  @override
  Future<Result<RevokedSessions, RuntimeSessionFailure>>
  revokeOtherSessions() async => result;
}

class _CountingRepository implements RuntimeSessionRepository {
  int calls = 0;

  @override
  Future<Result<RevokedSessions, RuntimeSessionFailure>>
  revokeOtherSessions() async {
    calls++;
    return const Success(RevokedSessions(0));
  }
}
