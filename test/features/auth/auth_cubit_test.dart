import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_out.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_state.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/ensure_user_profile.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.authResult);

  final Result<AuthUser, AuthFailure> authResult;
  int signInCalls = 0;
  int signUpCalls = 0;

  @override
  AuthUser? currentUser() => null;

  @override
  Stream<AuthUser?> authStateChanges() => const Stream.empty();

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    signInCalls++;
    return authResult;
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    signUpCalls++;
    return authResult;
  }

  @override
  Future<Result<Unit, AuthFailure>> signOut() async {
    return const Result.success(unit);
  }
}

class _FakeUserRepository implements UserRepository {
  int ensureCalls = 0;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    ensureCalls++;
    return Result.success(
      UserProfile(
        id: id,
        email: email,
        displayName: displayName,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    return const Result.error(UserFailure(UserFailureKind.notFound));
  }
}

AuthCubit _cubitWith(
  _FakeAuthRepository authRepository,
  _FakeUserRepository userRepository,
) {
  return AuthCubit(
    signUp: SignUpWithEmailAndPassword(authRepository),
    signIn: SignInWithEmailAndPassword(authRepository),
    ensureUserProfile: EnsureUserProfile(userRepository),
    signOut: SignOut(authRepository),
  );
}

void main() {
  group('AuthCubit', () {
    test('blockiert ungueltige E-Mail lokal', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.updateName('Ada');
      cubit.updateEmail('ada');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect(cubit.state.status, AuthStatus.failure);
      expect(repository.signUpCalls, 0);
      await cubit.close();
    });

    test('emittiert submitting und success bei Registrierung', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      final states = cubit.stream.take(2).toList();
      cubit.updateName('Ada');
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect((await states).map((state) => state.status), [
        AuthStatus.submitting,
        AuthStatus.success,
      ]);
      expect(repository.signUpCalls, 1);
      expect(userRepository.ensureCalls, 1);
      await cubit.close();
    });

    test('nutzt Login-Use-Case im Login-Modus', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.changeMode(AuthMode.signIn);
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect(cubit.state.status, AuthStatus.success);
      expect(repository.signInCalls, 1);
      expect(repository.signUpCalls, 0);
      expect(userRepository.ensureCalls, 1);
      await cubit.close();
    });

    test('ignoriert spaete Profil-Antwort nach close()', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _BlockingUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.updateName('Ada');
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      final submitFuture = cubit.submit();
      await cubit.close();
      userRepository.complete();
      await submitFuture;
      expect(cubit.isClosed, isTrue);
    });
  });
}

class _BlockingUserRepository extends _FakeUserRepository {
  final _completer = Completer<Result<UserProfile, UserFailure>>();

  void complete() => _completer.complete(_successProfile());

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) {
    ensureCalls++;
    return _completer.future;
  }
}

Result<UserProfile, UserFailure> _successProfile() {
  return Result.success(
    UserProfile(
      id: const UniqueId('user.1'),
      email: UserEmail.tryCreate('ada@example.com')!,
      displayName: 'Ada',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  );
}

Result<AuthUser, AuthFailure> _success() {
  return const Result.success(
    AuthUser(
      id: UniqueId('user.1'),
      email: 'ada@example.com',
      displayName: 'Ada',
    ),
  );
}
