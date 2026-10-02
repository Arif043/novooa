import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/auth/domain/repositories/auth_repository.dart';
import 'package:syscat2/features/user/domain/entities/user_failure.dart';
import 'package:syscat2/features/user/domain/entities/user_profile.dart';
import 'package:syscat2/features/user/domain/repositories/user_repository.dart';

class GetCurrentUserProfile {
  const GetCurrentUserProfile({
    required this._authRepository,
    required this._userRepository,
  });

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<Result<UserProfile, UserFailure>> call() async {
    final authUser = _authRepository.currentUser();
    if (authUser == null) {
      return Error(UserFailure(UserFailureKind.unauthenticated));
    }

    return _userRepository.getProfile(authUser.id);
  }
}
