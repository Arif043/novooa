enum AuthMode { signUp, signIn }

enum AuthFormStatus { initial, submitting, success, failure }

class AuthFormState {
  const AuthFormState({
    this.mode = AuthMode.signUp,
    this.status = AuthFormStatus.initial,
    this.message,
  });

  final AuthMode mode;
  final AuthFormStatus status;
  final String? message;

  bool get isSubmitting => status == AuthFormStatus.submitting;

  AuthFormState copyWith({
    AuthMode? mode,
    AuthFormStatus? status,
    String? message,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      message: message,
    );
  }
}
