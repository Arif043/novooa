import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Die App-interne Identität; wer tatsächlich angemeldet ist, kennt die
/// Runtime über die Sitzung (siehe `CurrentRuntimeUserCubit`).
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
}
