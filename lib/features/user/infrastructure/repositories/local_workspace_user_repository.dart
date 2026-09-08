import 'package:multiple_result/multiple_result.dart';

import '../../../../core/entities/unique_id.dart';
import '../../domain/entities/user_email.dart';
import '../../domain/entities/user_failure.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_repository.dart';

class LocalWorkspaceUserRepository implements UserRepository {
  const LocalWorkspaceUserRepository({required this.userId});

  final String userId;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async => Success(_profileFor(id, displayName: displayName));

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    if (id.value != userId) {
      return Error(UserFailure(UserFailureKind.notFound));
    }
    return Success(_profileFor(id));
  }

  UserProfile _profileFor(
    UniqueId id, {
    String displayName = 'Lokaler Benutzer',
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: UserEmail.tryCreate('local@novooa.invalid')!,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
  }
}
