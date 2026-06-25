import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/domain/unique_id.dart';
import 'package:syscat2/features/user/domain/entities/user_email.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';
import 'package:syscat2/features/user/domain/usecases/ensure_user_profile.dart';

class _InMemoryUserRepository implements UserRepository {
  UserProfile? profile;

  @override
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  }) async {
    final now = DateTime(2026);
    profile = UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: profile?.createdAt ?? now,
      updatedAt: now,
    );
    return Result.success(profile!);
  }

  @override
  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id) async {
    final current = profile;
    if (current == null) {
      return const Result.error(UserFailure(UserFailureKind.notFound));
    }
    return Result.success(current);
  }
}

void main() {
  test('EnsureUserProfile speichert UserProfile ueber Repository', () async {
    final repository = _InMemoryUserRepository();
    final useCase = EnsureUserProfile(repository);
    final userProfileOrFailure = await useCase(
      EnsureUserProfileParams(
        id: const UniqueId('user.1'),
        email: UserEmail.tryCreate('ada@example.com')!,
        displayName: 'Ada',
      ),
    );
    expect(userProfileOrFailure.isSuccess(), isTrue);
    expect(repository.profile?.id, const UniqueId('user.1'));
    expect(repository.profile?.email.value, 'ada@example.com');
  });
}
