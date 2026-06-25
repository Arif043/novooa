import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/domain/unique_id.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository(this._firebaseAuth);

  final firebase.FirebaseAuth _firebaseAuth;

  @override
  AuthUser? currentUser() => _mapUser(_firebaseAuth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.value,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      final user = credential.user ?? _firebaseAuth.currentUser;
      if (user == null) return _unknownFailure();
      return Result.success(_mapUser(user)!);
    } on firebase.FirebaseAuthException catch (error) {
      return Result.error(_mapFailure(error.code));
    } catch (_) {
      return _unknownFailure();
    }
  }

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.value,
        password: password,
      );
      final user = credential.user ?? _firebaseAuth.currentUser;
      if (user == null) return _unknownFailure();
      return Result.success(_mapUser(user)!);
    } on firebase.FirebaseAuthException catch (error) {
      return Result.error(_mapFailure(error.code));
    } catch (_) {
      return _unknownFailure();
    }
  }

  AuthUser? _mapUser(firebase.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: UniqueId(user.uid),
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    );
  }

  AuthFailure _mapFailure(String code) {
    return switch (code) {
      'invalid-email' => const AuthFailure(AuthFailureKind.invalidEmail),
      'weak-password' => const AuthFailure(AuthFailureKind.weakPassword),
      'email-already-in-use' => const AuthFailure(
        AuthFailureKind.emailAlreadyInUse,
      ),
      'invalid-credential' => const AuthFailure(
        AuthFailureKind.invalidCredentials,
      ),
      'user-not-found' => const AuthFailure(AuthFailureKind.invalidCredentials),
      'wrong-password' => const AuthFailure(AuthFailureKind.invalidCredentials),
      'network-request-failed' => const AuthFailure(AuthFailureKind.network),
      _ => const AuthFailure(AuthFailureKind.unknown),
    };
  }

  Result<AuthUser, AuthFailure> _unknownFailure() {
    return const Result.error(AuthFailure(AuthFailureKind.unknown));
  }
}
