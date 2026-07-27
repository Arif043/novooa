import 'dart:async';

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

class TestAuthRepository implements AuthRepository {
  TestAuthRepository(this._user);

  final AuthUser? _user;
  final authStates = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => authStates.stream;

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

  Future<void> close() => authStates.close();

  void emit(AuthUser? user) => authStates.add(user);
}

class TestTokenProvider implements FcmTokenProvider {
  TestTokenProvider(this._token, {this.permissionGranted = true});

  final String _token;
  final refreshes = StreamController<String>.broadcast();
  bool permissionGranted;
  bool permissionRequested = false;
  bool tokenDeleted = false;

  @override
  Future<String?> currentToken({required bool requestPermission}) async {
    permissionRequested = requestPermission;
    if (requestPermission) permissionGranted = true;
    return permissionGranted ? _token : null;
  }

  @override
  Future<void> deleteToken() async => tokenDeleted = true;

  @override
  String get platform => 'android';

  @override
  Stream<String> get tokenRefreshes => refreshes.stream;

  Future<void> close() => refreshes.close();
}

class TestDeviceRepository implements NotificationDeviceRepository {
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

FcmBootstrapper testBootstrapper(
  TestAuthRepository authRepository,
  TestTokenProvider tokenProvider,
  TestDeviceRepository deviceRepository,
) {
  return FcmBootstrapper(
    authRepository,
    tokenProvider,
    RegisterNotificationDevice(deviceRepository),
    UnregisterNotificationDevice(deviceRepository),
  );
}

Future<void> disposeTestResources(
  List<FcmBootstrapper> bootstrappers,
  List<TestAuthRepository> authRepositories,
  List<TestTokenProvider> tokenProviders,
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

AuthUser testUser(String id) {
  return AuthUser(id: UniqueId(id), email: '$id@example.com', displayName: id);
}
