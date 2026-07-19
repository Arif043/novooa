enum AuthMode { signUp, signIn }

enum AuthFormStatus { initial, submitting, success, failure }

/// Bündelt Modus, Status und die reinen Eingabewerte des Auth-Formulars.
///
/// Die Text-Werte liegen bewusst hier — nicht mehr als private Felder im
/// Cubit — damit `changeMode` und `success` sie explizit zurücksetzen
/// können, statt sich auf den Widget-Lifecycle zu verlassen.
class AuthFormState {
  const AuthFormState({
    this.mode = AuthMode.signUp,
    this.status = AuthFormStatus.initial,
    this.name = '',
    this.email = '',
    this.password = '',
    this.message,
  });

  final AuthMode mode;
  final AuthFormStatus status;
  final String name;
  final String email;
  final String password;
  final String? message;

  bool get isSubmitting => status == AuthFormStatus.submitting;

  AuthFormState copyWith({
    AuthMode? mode,
    AuthFormStatus? status,
    String? name,
    String? email,
    String? password,
    String? message,
    bool clearMessage = false,
  }) {
    return AuthFormState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
