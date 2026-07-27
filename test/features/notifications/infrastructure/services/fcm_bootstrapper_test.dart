import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/notifications/domain/entities/notification_device_token.dart';
import 'package:syscat2/features/notifications/domain/repositories/notification_device_repository.dart';
import 'package:syscat2/features/notifications/domain/usecases/register_notification_device.dart';
import 'package:syscat2/features/notifications/domain/usecases/unregister_notification_device.dart';
import 'package:syscat2/features/notifications/infrastructure/datasources/firebase_messaging_token_provider.dart';
import 'package:syscat2/features/notifications/infrastructure/services/fcm_bootstrapper.dart';

class _AuthRepository implements AuthRepository {
  _AuthRepository(this._user);

  final AuthUser? _user;
  final _authStates = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => _authStates.stream;

  @override
  AuthUser? currentUser() => _user;

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<Result<Unit, AuthFailure>> signOut() => throw UnimplementedError();

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) => throw UnimplementedError();

  Future<void> close() => _authStates.close();

  void emit(AuthUser? user) => _authStates.add(user);
}

class _TokenProvider implements FcmTokenProvider {
  _TokenProvider(this._token);

  final String _token;
  final _refreshes = StreamController<String>.broadcast();
  bool tokenDeleted = false;

  @override
  Future<String?> currentToken() async => _token;

  @override
  Future<void> deleteToken() async => tokenDeleted = true;

  @override
  String get platform => 'android';

  @override
  Stream<String> get tokenRefreshes => _refreshes.stream;

  Future<void> close() => _refreshes.close();
}

class _DeviceRepository implements NotificationDeviceRepository {
  final savedTokens = <NotificationDeviceToken>[];
  final deletedTokens = <({String userId, String token})>[];

  @override
  Future<void> deleteToken({
    required String userId,
    required String token,
  }) async {
    deletedTokens.add((userId: userId, token: token));
  }

  @override
  Future<void> saveToken(NotificationDeviceToken token) async {
    savedTokens.add(token);
  }
}

FcmBootstrapper _bootstrapper(
  _AuthRepository authRepository,
  _TokenProvider tokenProvider,
  _DeviceRepository deviceRepository,
) {
  return FcmBootstrapper(
    authRepository,
    tokenProvider,
    RegisterNotificationDevice(deviceRepository),
    UnregisterNotificationDevice(deviceRepository),
  );
}

void main() {
  group('FcmBootstrapper', () {
    test(
      'registriert unterschiedliche Geraete-Tokens fuer denselben Nutzer',
      () async {
        final user = _user('kunde-1');
        final deviceRepository = _DeviceRepository();
        final firstAuth = _AuthRepository(user);
        final secondAuth = _AuthRepository(user);
        final firstProvider = _TokenProvider('token-telefon');
        final secondProvider = _TokenProvider('token-tablet');
        final firstBootstrapper = _bootstrapper(
          firstAuth,
          firstProvider,
          deviceRepository,
        );
        final secondBootstrapper = _bootstrapper(
          secondAuth,
          secondProvider,
          deviceRepository,
        );

        await firstBootstrapper.start();
        await secondBootstrapper.start();

        expect(deviceRepository.savedTokens, hasLength(2));
        expect(
          deviceRepository.savedTokens.map((token) => token.userId),
          everyElement(user.id.value),
        );
        expect(
          deviceRepository.savedTokens.map((token) => token.token),
          containsAll(['token-telefon', 'token-tablet']),
        );

        await _disposeAll(
          [firstBootstrapper, secondBootstrapper],
          [firstAuth, secondAuth],
          [firstProvider, secondProvider],
        );
      },
    );

    test('entfernt die alte Kontozuordnung vor einem Konto-Wechsel', () async {
      final firstUser = _user('kunde-1');
      final authRepository = _AuthRepository(firstUser);
      final tokenProvider = _TokenProvider('token-telefon');
      final deviceRepository = _DeviceRepository();
      final bootstrapper = _bootstrapper(
        authRepository,
        tokenProvider,
        deviceRepository,
      );

      await bootstrapper.start();
      authRepository.emit(_user('kunde-2'));
      await Future<void>.delayed(Duration.zero);

      expect(deviceRepository.deletedTokens, [
        (userId: firstUser.id.value, token: 'token-telefon'),
      ]);
      expect(deviceRepository.savedTokens.last.userId, 'kunde-2');
      expect(tokenProvider.tokenDeleted, isFalse);

      await _disposeAll([bootstrapper], [authRepository], [tokenProvider]);
    });
  });
}

Future<void> _disposeAll(
  List<FcmBootstrapper> bootstrappers,
  List<_AuthRepository> authRepositories,
  List<_TokenProvider> tokenProviders,
) async {
  for (final bootstrapper in bootstrappers) {
    await bootstrapper.dispose();
  }
  for (final authRepository in authRepositories) {
    await authRepository.close();
  }
  for (final tokenProvider in tokenProviders) {
    await tokenProvider.close();
  }
}

AuthUser _user(String id) {
  return AuthUser(id: UniqueId(id), email: '$id@example.com', displayName: id);
}
