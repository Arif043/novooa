enum AuthFailureKind {
  invalidName,
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  invalidCredentials,
  accountDisabled,
  rateLimited,
  operationNotAllowed,
  profileSyncFailed,
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
      AuthFailureKind.accountDisabled =>
        'Dieses Konto ist deaktiviert. Bitte wende dich an den Support.',
      AuthFailureKind.rateLimited =>
        'Zu viele Versuche. Warte kurz und versuche es erneut.',
      AuthFailureKind.operationNotAllowed =>
        'Diese Anmeldemethode ist aktuell nicht aktiviert.',
      AuthFailureKind.profileSyncFailed =>
        'Konto konnte nicht vollständig eingerichtet werden. '
            'Bitte versuche es erneut.',
      AuthFailureKind.network =>
        'Anmeldung aktuell nicht möglich. Prüfe deine Verbindung.',
      AuthFailureKind.unknown =>
        'Aktion fehlgeschlagen. Bitte versuche es erneut.',
    };
  }
}
