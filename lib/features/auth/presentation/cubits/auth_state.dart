enum AuthMode { signUp, signIn }

enum AuthStatus { initial, submitting, success, failure }

class AuthState {
  const AuthState({
    this.mode = AuthMode.signUp,
    this.status = AuthStatus.initial,
    this.message,
  });

  final AuthMode mode;
  final AuthStatus status;
  final String? message;

  bool get isSubmitting => status == AuthStatus.submitting;

  AuthState copyWith({AuthMode? mode, AuthStatus? status, String? message}) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      message: message,
    );
  }
}
