import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';
import 'package:syscat2/features/user/infrastructure/repositories/local_workspace_user_repository.dart';

void main() {
  test('returns the profile of the local workspace user', () async {
    const repository = LocalWorkspaceUserRepository(userId: 'local-user');

    final profileOrFailure = await repository.getProfile(
      const UniqueId('local-user'),
    );

    expect(profileOrFailure, isA<Success>());
    profileOrFailure.when(
      (profile) => expect(profile.displayName, 'Lokaler Benutzer'),
      (failure) => fail(failure.message),
    );
  });
}
