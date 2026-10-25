import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session.dart';
import 'package:syscat2/features/runtime_sessions/domain/entities/runtime_session_failure.dart';
import 'package:syscat2/features/runtime_sessions/presentation/cubits/runtime_sessions_state.dart';

import 'runtime_sessions_fakes.dart';

const _unavailable = RuntimeSessionFailure(
  RuntimeSessionFailureKind.runtimeUnavailable,
);

List<String> _ids(Object? state) => (state! as RuntimeSessionsLoaded).sessions
    .map((session) => session.id.value)
    .toList();

void main() {
  test('lädt die Sitzungen des eigenen Kontos', () async {
    final cubit = cubitWith(FakeRuntimeSessionRepository());

    await cubit.load();

    expect(_ids(cubit.state), ['a', 'b']);
    await cubit.close();
  });

  test('zeigt einen Ladefehler mit dem Grund', () async {
    final repository = FakeRuntimeSessionRepository()
      ..sessionsOrFailure = const Error(_unavailable);
    final cubit = cubitWith(repository);

    await cubit.load();

    expect(
      (cubit.state as RuntimeSessionsLoadFailed).failure.kind,
      RuntimeSessionFailureKind.runtimeUnavailable,
    );
    await cubit.close();
  });

  test('meldet ein Gerät ab und nimmt es aus der Liste', () async {
    final repository = FakeRuntimeSessionRepository();
    final cubit = cubitWith(repository);
    await cubit.load();
    final states = <RuntimeSessionsState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.revoke(sessionFixture('b'));

    expect(
      (states.first as RuntimeSessionsLoaded).revoking,
      isA<RevokingSession>(),
    );
    expect(repository.revokedIds, [const RuntimeSessionId('b')]);
    expect(_ids(cubit.state), ['a']);
    expect(
      (cubit.state as RuntimeSessionsLoaded).notice,
      isA<SessionRevokedNotice>(),
    );
    await subscription.cancel();
    await cubit.close();
  });

  test('eine schon beendete Sitzung verschwindet mit Hinweis', () async {
    final repository = FakeRuntimeSessionRepository()
      ..revokeOrFailure = const Error(
        RuntimeSessionFailure(RuntimeSessionFailureKind.notFound),
      );
    final cubit = cubitWith(repository);
    await cubit.load();

    await cubit.revoke(sessionFixture('b'));

    expect(_ids(cubit.state), ['a']);
    expect(
      (cubit.state as RuntimeSessionsLoaded).notice,
      isA<RevokeFailedNotice>(),
    );
    await cubit.close();
  });

  test('ein Fehler beim Abmelden lässt die Liste stehen', () async {
    final repository = FakeRuntimeSessionRepository()
      ..revokeOrFailure = const Error(_unavailable);
    final cubit = cubitWith(repository);
    await cubit.load();

    await cubit.revoke(sessionFixture('b'));

    final state = cubit.state as RuntimeSessionsLoaded;
    expect(_ids(state), ['a', 'b']);
    expect(state.isBusy, isFalse);
    expect(state.notice, isA<RevokeFailedNotice>());
    await cubit.close();
  });

  test('die eigene Sitzung wird hier nie abgemeldet', () async {
    final repository = FakeRuntimeSessionRepository();
    final cubit = cubitWith(repository);
    await cubit.load();

    await cubit.revoke(sessionFixture('a', isCurrent: true));

    expect(repository.revokedIds, isEmpty);
    await cubit.close();
  });

  test('andere Geräte abmelden behält nur dieses Gerät', () async {
    final repository = FakeRuntimeSessionRepository()
      ..revokeOthersOrFailure = const Success(1);
    final cubit = cubitWith(repository);
    await cubit.load();

    await cubit.revokeOthers();

    final state = cubit.state as RuntimeSessionsLoaded;
    expect(_ids(state), ['a']);
    expect((state.notice! as OthersRevokedNotice).count, 1);
    await cubit.close();
  });

  test('startet keine zweite Abmeldung, solange eine läuft', () async {
    final repository = FakeRuntimeSessionRepository();
    final cubit = cubitWith(repository);
    await cubit.load();

    final first = cubit.revoke(sessionFixture('b'));
    await cubit.revokeOthers();
    await first;

    expect(_ids(cubit.state), ['a']);
    expect(
      (cubit.state as RuntimeSessionsLoaded).notice,
      isA<SessionRevokedNotice>(),
    );
    await cubit.close();
  });
}
