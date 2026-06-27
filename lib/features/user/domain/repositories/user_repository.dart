import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/entities/unique_id.dart';

import '../entities/user_email.dart';
import '../entities/user_failure.dart';
import '../entities/user_profile.dart';

abstract interface class UserRepository {
  Future<Result<UserProfile, UserFailure>> ensureProfile({
    required UniqueId id,
    required UserEmail email,
    required String displayName,
  });

  Future<Result<UserProfile, UserFailure>> getProfile(UniqueId id);
}
