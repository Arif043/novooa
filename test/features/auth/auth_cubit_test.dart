import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/auth/domain/entities/auth_failure.dart';
import 'package:syscat2/features/auth/domain/entities/auth_user.dart';
import 'package:syscat2/features/auth/domain/entities/email_address.dart';
import 'package:syscat2/features/auth/domain/entities/unique_id.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import 'package:syscat2/features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:syscat2/features/auth/presentation/cubits/auth_state.dart';

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
}

AuthCubit _cubitWith(_FakeAuthRepository repository) {
  return AuthCubit(
    signUp: SignUpWithEmailAndPassword(repository),
    signIn: SignInWithEmailAndPassword(repository),
  );
}

void main() {
  group('AuthCubit', () {
    test('blockiert ungueltige E-Mail lokal', () async {
      final repository = _FakeAuthRepository(_success());
      final cubit = _cubitWith(repository);
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
      final cubit = _cubitWith(repository);
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
      await cubit.close();
    });

    test('nutzt Login-Use-Case im Login-Modus', () async {
      final repository = _FakeAuthRepository(_success());
      final cubit = _cubitWith(repository);
      cubit.changeMode(AuthMode.signIn);
      cubit.updateEmail('ada@example.com');
      cubit.updatePassword('sicheres-passwort');
      await cubit.submit();
      expect(cubit.state.status, AuthStatus.success);
      expect(repository.signInCalls, 1);
      expect(repository.signUpCalls, 0);
      await cubit.close();
    });
  });
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
