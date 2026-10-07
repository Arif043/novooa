import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/auth/domain/entities/new_password.dart';
import 'package:syscat2/features/auth/domain/entities/password_failure.dart';
import 'package:syscat2/features/auth/infrastructure/repositories/firebase_password_repository.dart';
import 'package:syscat2/features/auth/infrastructure/repositories/http_password_repository.dart';

void main() {
  final password = NewPassword.parse('new-password')!;

  test('Cloud ändert nur das Passwort des aktuellen Nutzers', () async {
    final user = _User();
    final passwordOrFailure = await FirebasePasswordRepository(
      _Auth(user),
    ).updatePassword(password);
    expect(passwordOrFailure.isSuccess(), isTrue);
    expect(user.password, 'new-password');
  });

  test('Cloud meldet eine fehlende Anmeldung', () async {
    final passwordOrFailure = await FirebasePasswordRepository(
      _Auth(null),
    ).updatePassword(password);
    expect(passwordOrFailure.tryGetError(), PasswordFailure.signInRequired);
  });

  for (final entry in {
    'requires-recent-login': PasswordFailure.recentLoginRequired,
    'weak-password': PasswordFailure.invalidPassword,
    'network-request-failed': PasswordFailure.network,
    'too-many-requests': PasswordFailure.rateLimited,
  }.entries) {
    test('Cloud übersetzt ${entry.key}', () async {
      final user = _User()..failure = FirebaseAuthException(code: entry.key);
      final passwordOrFailure = await FirebasePasswordRepository(
        _Auth(user),
      ).updatePassword(password);
      expect(passwordOrFailure.tryGetError(), entry.value);
    });
  }

  test(
    'Standalone sendet nur das neue Passwort an die authentifizierte Route',
    () async {
      final client = _Client();
      final passwordOrFailure = await HttpPasswordRepository(
        client,
      ).updatePassword(password);
      expect(passwordOrFailure.isSuccess(), isTrue);
      expect(client.path, '/v1/auth/password');
      expect(client.body, {'password': 'new-password'});
    },
  );

  for (final entry in {
    400: PasswordFailure.invalidPassword,
    401: PasswordFailure.signInRequired,
    429: PasswordFailure.rateLimited,
    500: PasswordFailure.unexpected,
  }.entries) {
    test('Standalone übersetzt HTTP ${entry.key}', () async {
      final client = _Client()
        ..failure = WorkspaceHttpException(
          entry.key,
          const WorkspaceApiError(message: 'Failure'),
        );
      final passwordOrFailure = await HttpPasswordRepository(
        client,
      ).updatePassword(password);
      expect(passwordOrFailure.tryGetError(), entry.value);
    });
  }

  test(
    'Standalone behandelt Zeitüberschreitung als Verbindungsfehler',
    () async {
      final client = _Client()..failure = TimeoutException('Timeout');
      final passwordOrFailure = await HttpPasswordRepository(
        client,
      ).updatePassword(password);
      expect(passwordOrFailure.tryGetError(), PasswordFailure.network);
    },
  );
}

class _Auth implements FirebaseAuth {
  _Auth(this.currentUser);

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  String? password;
  Object? failure;

  @override
  Future<void> updatePassword(String newPassword) async {
    if (failure != null) throw failure!;
    password = newPassword;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements WorkspaceApiClient {
  String? path;
  Map<String, Object?>? body;
  Object? failure;

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async {
    if (failure != null) throw failure!;
    this.path = path;
    this.body = body;
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
