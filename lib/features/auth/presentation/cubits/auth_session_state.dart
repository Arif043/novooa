import '../../domain/entities/auth_user.dart';

/// - `ready`: `currentUser` spiegelt Firebase- **und** Firestore-Wahrheit.
/// - `verifying`: Firebase meldet einen User, wir warten aber noch auf den
///   Firestore-Profil-Sync. `currentUser` bleibt in dieser Phase `null`,
///   damit der Router nicht zu früh in die App weiterleitet.
/// - `signingOut`: laufender SignOut.
/// - `failure`: letzter SignOut- oder Verify-Versuch ist gescheitert.
enum AuthSessionStatus { ready, verifying, signingOut, failure }

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

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthSessionState(
      currentUser: currentUser,
      status: status ?? this.status,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
