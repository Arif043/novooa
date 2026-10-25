import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session_failure.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/session_device.dart';
import 'package:syscat2/features/runtime_sessions/domain/repositories/runtime_session_repository.dart';
import 'package:syscat2/features/runtime_sessions/domain/usecases/load_runtime_sessions.dart';
import 'package:syscat2/features/runtime_sessions/domain/usecases/revoke_other_runtime_sessions.dart';
import 'package:syscat2/features/runtime_sessions/domain/usecases/revoke_runtime_session.dart';
import 'package:syscat2/features/runtime_sessions/presentation/cubits/runtime_sessions_cubit.dart';

RuntimeSession sessionFixture(String id, {bool isCurrent = false}) =>
    RuntimeSession(
      id: RuntimeSessionId(id),
      isCurrent: isCurrent,
      signedInAt: DateTime(2026, 10, 1),
      lastActiveAt: DateTime(2026, 10, 2),
      device: const SessionDevice(
        app: 'novooa',
        os: DeviceOs.macos,
        browser: 'Chrome',
      ),
    );

class FakeRuntimeSessionRepository implements RuntimeSessionRepository {
  Result<List<RuntimeSession>, RuntimeSessionFailure> sessionsOrFailure =
      Success([sessionFixture('a', isCurrent: true), sessionFixture('b')]);
  Result<Unit, RuntimeSessionFailure> revokeOrFailure = const Success(unit);
  Result<int, RuntimeSessionFailure> revokeOthersOrFailure = const Success(1);
  final revokedIds = <RuntimeSessionId>[];

  @override
  Future<Result<List<RuntimeSession>, RuntimeSessionFailure>>
  listSessions() async => sessionsOrFailure;

  @override
  Future<Result<Unit, RuntimeSessionFailure>> revokeSession(
    RuntimeSessionId id,
  ) async {
    revokedIds.add(id);
    return revokeOrFailure;
  }

  @override
  Future<Result<int, RuntimeSessionFailure>> revokeOtherSessions() async =>
      revokeOthersOrFailure;
}

RuntimeSessionsCubit cubitWith(FakeRuntimeSessionRepository repository) =>
    RuntimeSessionsCubit(
      LoadRuntimeSessions(repository),
      RevokeRuntimeSession(repository),
      RevokeOtherRuntimeSessions(repository),
    );
