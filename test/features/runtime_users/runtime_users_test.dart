import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';
import 'package:syscat2/features/runtime_users/domain/entities/runtime_user.dart';
import 'package:syscat2/features/runtime_users/domain/entities/runtime_user_failure.dart';
import 'package:syscat2/features/runtime_users/domain/repositories/runtime_user_repository.dart';
import 'package:syscat2/features/runtime_users/domain/usecases/runtime_user_use_cases.dart';
import 'package:syscat2/features/runtime_users/infrastructure/repositories/local_runtime_user_repository.dart';
import 'package:syscat2/features/runtime_users/presentation/cubits/current_runtime_user_cubit.dart';
import 'package:syscat2/features/runtime_users/presentation/cubits/runtime_users_cubit.dart';
import 'package:syscat2/features/runtime_users/presentation/cubits/runtime_users_state.dart';
import 'package:syscat2/features/runtime_users/presentation/widgets/runtime_user_list.dart';

const _anna = RuntimeUser(
  uid: 'u-anna',
  loginName: 'anna',
  displayName: 'Anna Admin',
  role: RuntimeRole.admin,
  hasPassword: true,
);
const _ben = RuntimeUser(
  uid: 'u-ben',
  loginName: 'ben',
  displayName: 'Ben',
  role: RuntimeRole.member,
  hasPassword: false,
);
final _invitation = UserInvitation(
  code: 'ABCD-EFGH-JKMN-PQRS',
  expiresAt: DateTime(2026, 10, 22),
);

void main() {
  group('LocalRuntimeUserRepository', () {
    test('legt Konten an und liest Einladungscode und Konto zurück', () async {
      final api = _Api({
        'POST /v1/users': {
          'user': _json(_ben),
          'invitation': {'code': 'ABCD', 'expiresAt': '2026-10-22T00:00:00Z'},
        },
      });
      final repository = LocalRuntimeUserRepository(api, _NoChannel());

      final createdOrFailure = await repository.createUser(
        const NewRuntimeUser(
          displayName: ' Ben ',
          loginName: 'ben',
          role: RuntimeRole.member,
        ),
      );

      expect(createdOrFailure.tryGetSuccess()?.user, _ben);
      expect(createdOrFailure.tryGetSuccess()?.invitation.code, 'ABCD');
      expect(api.bodies.single, {
        'displayName': 'Ben',
        'loginName': 'ben',
        'role': 'member',
      });
    });

    test('übersetzt den Fehlercode der Runtime in die Fehlerart', () async {
      final api = _Api(
        {},
        failures: {
          'PUT /v1/users/u-anna': WorkspaceHttpException(
            409,
            const WorkspaceApiError(message: 'nein', code: 'last_admin'),
          ),
        },
      );
      final repository = LocalRuntimeUserRepository(api, _NoChannel());

      final userOrFailure = await repository.changeRole(
        'u-anna',
        RuntimeRole.member,
      );

      expect(
        userOrFailure.tryGetError()?.kind,
        RuntimeUserFailureKind.lastAdmin,
      );
      expect(api.bodies.single, {'role': 'member'});
    });
  });

  group('CurrentRuntimeUserCubit', () {
    test('kennt Konto und Rolle der angemeldeten Person', () async {
      final cubit = CurrentRuntimeUserCubit(
        LoadCurrentRuntimeUser(_Repository(current: const Success(_anna))),
      );
      await cubit.load();
      expect(cubit.state, const CurrentRuntimeUserLoaded(_anna));
      expect(cubit.state.isAdmin, isTrue);
    });

    test('ohne Konto gilt niemand als Admin', () async {
      final cubit = CurrentRuntimeUserCubit(
        LoadCurrentRuntimeUser(
          _Repository(
            current: const Error(
              RuntimeUserFailure(RuntimeUserFailureKind.unavailable),
            ),
          ),
        ),
      );
      await cubit.load();
      expect(cubit.state, const CurrentRuntimeUserUnavailable());
      expect(cubit.state.isAdmin, isFalse);
    });
  });

  group('RuntimeUsersCubit', () {
    test('zeigt nach dem Anlegen den Einladungscode einmalig', () async {
      final repository = _Repository();
      final cubit = _usersCubit(repository);
      await cubit.load();
      repository.users.add(
        const RuntimeUserOverview(users: [_anna], maxUsers: 5),
      );
      await pumpEventQueue();
      expect(cubit.state.status, RuntimeUsersStatus.ready);

      final created = await cubit.create(
        const NewRuntimeUser(
          displayName: 'Ben',
          loginName: 'ben',
          role: RuntimeRole.member,
        ),
      );

      expect(created, isTrue);
      expect(
        cubit.state.issuedInvitation,
        IssuedInvitation(displayName: 'Ben', invitation: _invitation),
      );
      cubit.noticeShown();
      expect(cubit.state.issuedInvitation, isNull);
      expect(cubit.state.overview.users, [_anna]);
      await cubit.close();
    });

    test('meldet ein volles Nutzerlimit als Fehler', () async {
      final repository = _Repository(
        createFailure: const RuntimeUserFailure(
          RuntimeUserFailureKind.userLimitReached,
        ),
      );
      final cubit = _usersCubit(repository);

      final created = await cubit.create(
        const NewRuntimeUser(
          displayName: 'Carla',
          loginName: 'carla',
          role: RuntimeRole.member,
        ),
      );

      expect(created, isFalse);
      expect(
        cubit.state.failure?.kind,
        RuntimeUserFailureKind.userLimitReached,
      );
      await cubit.close();
    });

    test('Passwort zurücksetzen liefert einen neuen Code', () async {
      final cubit = _usersCubit(_Repository());
      await cubit.resetPassword(_ben);
      expect(cubit.state.issuedInvitation?.displayName, 'Ben');
      await cubit.close();
    });
  });

  group('RuntimeUserList', () {
    testWidgets('zeigt Belegung, offene Einladungen und kein Menü fürs eigene '
        'Konto', (tester) async {
      await _pumpList(
        tester,
        const RuntimeUserOverview(users: [_anna, _ben], maxUsers: 5),
      );

      expect(find.text('2 von 5 Benutzern'), findsOneWidget);
      expect(find.textContaining('Einladung offen'), findsOneWidget);
      expect(find.textContaining('Du'), findsOneWidget);
      expect(find.byTooltip('Aktionen für Ben'), findsOneWidget);
      expect(find.text('AA'), findsOneWidget, reason: 'Initialen statt Noovi');
    });

    testWidgets('eine volle Lizenz sperrt „Benutzer hinzufügen“', (
      tester,
    ) async {
      await _pumpList(
        tester,
        const RuntimeUserOverview(users: [_anna, _ben], maxUsers: 2),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.textContaining('voll belegt'), findsOneWidget);
    });
  });
}

Future<void> _pumpList(
  WidgetTester tester,
  RuntimeUserOverview overview,
) async {
  final current = CurrentRuntimeUserCubit(
    LoadCurrentRuntimeUser(_Repository(current: const Success(_anna))),
  );
  await current.load();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: current),
            BlocProvider(create: (_) => _usersCubit(_Repository())),
          ],
          child: RuntimeUserList(overview: overview),
        ),
      ),
    ),
  );
}

RuntimeUsersCubit _usersCubit(_Repository repository) => RuntimeUsersCubit(
  WatchRuntimeUsers(repository),
  CreateRuntimeUser(repository),
  ChangeRuntimeUserRole(repository),
  ResetRuntimeUserPassword(repository),
  DeleteRuntimeUser(repository),
);

Map<String, Object?> _json(RuntimeUser user) => {
  'uid': user.uid,
  'loginName': user.loginName,
  'displayName': user.displayName,
  'role': user.role.name,
  'hasPassword': user.hasPassword,
  'createdAt': '2026-10-19T00:00:00Z',
};

class _Repository implements RuntimeUserRepository {
  _Repository({this.current = const Success(_anna), this.createFailure});

  final Result<RuntimeUser, RuntimeUserFailure> current;
  final RuntimeUserFailure? createFailure;
  final users = StreamController<RuntimeUserOverview>.broadcast();

  @override
  Future<Result<RuntimeUser, RuntimeUserFailure>> currentUser() async =>
      current;

  @override
  Stream<RuntimeUserOverview> watchUsers() => users.stream;

  @override
  Future<Result<CreatedRuntimeUser, RuntimeUserFailure>> createUser(
    NewRuntimeUser user,
  ) async {
    if (createFailure != null) return Error(createFailure!);
    return Success(
      CreatedRuntimeUser(
        user: RuntimeUser(
          uid: 'neu',
          loginName: user.loginName,
          displayName: user.displayName,
          role: user.role,
          hasPassword: false,
        ),
        invitation: _invitation,
      ),
    );
  }

  @override
  Future<Result<RuntimeUser, RuntimeUserFailure>> changeRole(
    String uid,
    RuntimeRole role,
  ) async => const Success(_ben);

  @override
  Future<Result<UserInvitation, RuntimeUserFailure>> resetPassword(
    String uid,
  ) async => Success(_invitation);

  @override
  Future<Result<Unit, RuntimeUserFailure>> deleteUser(String uid) async =>
      const Success(unit);
}

class _Api implements WorkspaceApiClient {
  _Api(this.responses, {this.failures = const {}});

  final Map<String, Map<String, Object?>> responses;
  final Map<String, Object> failures;
  final bodies = <Map<String, Object?>>[];

  Future<Map<String, Object?>> _answer(String key) async {
    final failure = failures[key];
    if (failure != null) throw failure;
    return responses[key] ?? (throw StateError('Keine Antwort für $key'));
  }

  @override
  Future<Map<String, Object?>> post(String path, Map<String, Object?> body) {
    bodies.add(body);
    return _answer('POST $path');
  }

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) {
    bodies.add(body);
    return _answer('PUT $path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoChannel implements WorkspaceRealtimeChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
