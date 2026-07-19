import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_out.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_session_cubit.dart';

class _SessionAuthRepository implements AuthRepository {
  _SessionAuthRepository(this._currentUser);

  AuthUser? _currentUser;
  int signOutCalls = 0;
  final controller = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? currentUser() => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => controller.stream;

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    return Result.success(_user(email.value));
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    return Result.success(_user(email.value));
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    signOutCalls++;
    _currentUser = null;
    return const Result.success(unit);
  }

  Future<void> close() => controller.close();
}

void main() {
  group('AuthSessionCubit', () {
    test('initialisiert sich aus dem aktuellen Nutzer', () async {
      final repository = _SessionAuthRepository(_user('ada@example.com'));
      final cubit = _cubitWith(repository);
      expect(cubit.state.currentUser?.email, 'ada@example.com');
      await cubit.close();
      await repository.close();
    });

    test('aktualisiert den Session-State aus dem Auth-Stream', () async {
      final repository = _SessionAuthRepository(null);
      final cubit = _cubitWith(repository);
      final nextState = cubit.stream.first;
      repository.controller.add(_user('grace@example.com'));
      expect((await nextState).currentUser?.email, 'grace@example.com');
      await cubit.close();
      await repository.close();
    });

    test('delegiert signOut und leert die Session', () async {
      final repository = _SessionAuthRepository(_user('ada@example.com'));
      final cubit = _cubitWith(repository);
      await cubit.signOut();
      expect(repository.signOutCalls, 1);
      expect(cubit.state.currentUser, isNull);
      await cubit.close();
      await repository.close();
    });
  });
}

AuthSessionCubit _cubitWith(_SessionAuthRepository repository) {
  return AuthSessionCubit(
    authRepository: repository,
    signOutUseCase: SignOut(repository),
  );
}

AuthUser _user(String email) {
  return AuthUser(
    id: const UniqueId('user.1'),
    email: email,
    displayName: 'Ada',
  );
}
