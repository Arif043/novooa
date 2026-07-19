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
import 'package:syscat2/features/auth/presentation/cubits/auth_form_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_form_state.dart';
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
  int signOutCalls = 0;

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
    signOutCalls++;
    return const Result.success(unit);
  }
}

class _FakeUserRepository implements UserRepository {
  int ensureCalls = 0;
  bool failEnsure = false;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    ensureCalls++;
    if (failEnsure) {
      return const Result.error(UserFailure(UserFailureKind.unknown));
    }
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

AuthFormCubit _cubitWith(
  _FakeAuthRepository authRepository,
  _FakeUserRepository userRepository,
) {
  return AuthFormCubit(
    signUpUseCase: SignUpWithEmailAndPassword(authRepository),
    signInUseCase: SignInWithEmailAndPassword(authRepository),
    ensureUserProfileUseCase: EnsureUserProfile(userRepository),
    signOutUseCase: SignOut(authRepository),
  );
}

void main() {
  group('AuthFormCubit', () {
    test('blockiert ungueltige E-Mail lokal', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.updateName('Ada');
      cubit.updateEmail('ada');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect(cubit.state.status, AuthFormStatus.failure);
      expect(repository.signUpCalls, 0);
      await cubit.close();
    });

    test('emittiert submitting und success bei Registrierung', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      final statuses = _collectSubmitStatuses(cubit);
      cubit.updateName('Ada');
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect(await statuses, [
        AuthFormStatus.submitting,
        AuthFormStatus.success,
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
      expect(cubit.state.status, AuthFormStatus.success);
      expect(repository.signInCalls, 1);
      expect(repository.signUpCalls, 0);
      expect(userRepository.ensureCalls, 1);
      await cubit.close();
    });

    test('setzt Eingaben bei changeMode zurueck', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _FakeUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.updateName('Ada');
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      cubit.changeMode(AuthMode.signIn);
      expect(cubit.state.name, isEmpty);
      expect(cubit.state.email, isEmpty);
      expect(cubit.state.password, isEmpty);
      await cubit.close();
    });

    test('ignoriert doppelten submit() waehrend submitting', () async {
      final repository = _FakeAuthRepository(_success());
      final userRepository = _BlockingUserRepository();
      final cubit = _cubitWith(repository, userRepository);
      cubit.updateName('Ada');
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      final firstSubmit = cubit.submit();
      final secondSubmit = cubit.submit();
      userRepository.complete();
      await Future.wait([firstSubmit, secondSubmit]);
      expect(repository.signUpCalls, 1);
      expect(userRepository.ensureCalls, 1);
      await cubit.close();
    });

    test(
      'loggt bei Profil-Sync-Fehler wieder aus und meldet Failure',
      () async {
        final repository = _FakeAuthRepository(_success());
        final userRepository = _FakeUserRepository()..failEnsure = true;
        final cubit = _cubitWith(repository, userRepository);
        cubit.updateName('Ada');
        cubit.updateEmail('ada@example.com');
        cubit.updatePassword('sicheres-passwort');
        await cubit.submit();
        expect(cubit.state.status, AuthFormStatus.failure);
        expect(
          cubit.state.message,
          const AuthFailure(AuthFailureKind.profileSyncFailed).message,
        );
        expect(cubit.state.password, isEmpty);
        expect(repository.signOutCalls, 1);
        await cubit.close();
      },
    );

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

Future<List<AuthFormStatus>> _collectSubmitStatuses(AuthFormCubit cubit) {
  return cubit.stream
      .map((state) => state.status)
      .where(
        (status) =>
            status == AuthFormStatus.submitting ||
            status == AuthFormStatus.success ||
            status == AuthFormStatus.failure,
      )
      .take(2)
      .toList();
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
