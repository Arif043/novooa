import 'package:multiple_result/multiple_result.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/email_address.dart';
import '../../domain/repositories/auth_repository.dart';

class LocalWorkspaceAuthRepository implements AuthRepository {
  const LocalWorkspaceAuthRepository(this._userId);

  final String _userId;

  @override
  Stream<AuthUser?> authStateChanges() => Stream.value(currentUser());

  @override
  AuthUser? currentUser() => AuthUser(
    id: UniqueId(_userId),
    email: '',
    displayName: 'Lokaler Benutzer',
  );

  @override
  Future<Result<AuthUser, AuthFailure>> signIn({
    required EmailAddress email,
    required String password,
  }) async => const Error(AuthFailure(AuthFailureKind.operationNotAllowed));

  @override
  Future<Result<Unit, AuthFailure>> signOut() async =>
      const Error(AuthFailure(AuthFailureKind.operationNotAllowed));

  @override
  Future<Result<AuthUser, AuthFailure>> signUp({
    required String name,
    required EmailAddress email,
    required String password,
  }) async => const Error(AuthFailure(AuthFailureKind.operationNotAllowed));
}
