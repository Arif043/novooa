import '../../domain/entities/auth_user.dart';

enum AuthSessionStatus { ready, signingOut, failure }

class AuthSessionState {
  const AuthSessionState({
    required this.currentUser,
    this.status = AuthSessionStatus.ready,
    this.message,
  });

  final AuthUser? currentUser;
  final AuthSessionStatus status;
  final String? message;

  bool get isSignedIn => currentUser != null;

  AuthSessionState copyWith({AuthSessionStatus? status, String? message}) {
    return AuthSessionState(
      currentUser: currentUser,
      status: status ?? this.status,
      message: message,
    );
  }
}
