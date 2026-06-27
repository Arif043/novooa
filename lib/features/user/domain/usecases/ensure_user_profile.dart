import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';

import '../entities/user_email.dart';
import '../entities/user_failure.dart';
import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class EnsureUserProfileParams {
  const EnsureUserProfileParams({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final UniqueId id;
  final UserEmail email;
  final String displayName;
}

class EnsureUserProfile {
  const EnsureUserProfile(this._repository);

  final UserRepository _repository;

  Future<Result<UserProfile, UserFailure>> call(
    EnsureUserProfileParams params,
  ) {
    return _repository.ensureProfile(
      id: params.id,
      email: params.email,
      displayName: params.displayName.trim(),
    );
  }
}
