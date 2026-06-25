enum AuthFailureKind {
  invalidName,
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  invalidCredentials,
  network,
  unknown,
}

class AuthFailure {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  String get message {
    return switch (kind) {
      AuthFailureKind.invalidName =>
        'Bitte gib deinen Namen mit mindestens 2 Zeichen ein.',
      AuthFailureKind.invalidEmail =>
        'Bitte gib eine gültige E-Mail-Adresse ein.',
      AuthFailureKind.weakPassword =>
        'Das Passwort ist zu schwach. Nutze mindestens 6 Zeichen.',
      AuthFailureKind.emailAlreadyInUse =>
        'Für diese E-Mail-Adresse gibt es bereits ein Konto.',
      AuthFailureKind.invalidCredentials =>
        'E-Mail oder Passwort ist nicht korrekt.',
      AuthFailureKind.network =>
        'Anmeldung aktuell nicht möglich. Prüfe deine Verbindung.',
      AuthFailureKind.unknown =>
        'Registrierung fehlgeschlagen. Bitte versuche es erneut.',
    };
  }
}
