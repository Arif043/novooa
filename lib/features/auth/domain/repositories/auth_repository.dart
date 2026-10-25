import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  AuthUser? currentUser();

  Stream<AuthUser?> authStateChanges();
}
