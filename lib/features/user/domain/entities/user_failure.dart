enum UserFailureKind {
  invalidEmail,
  invalidName,
  notFound,
  unknown,
  unauthenticated,
}

class UserFailure {
  const UserFailure(this.kind);

  final UserFailureKind kind;

  String get message {
    return switch (kind) {
      UserFailureKind.invalidEmail =>
        'Das Nutzerprofil enthält keine gültige E-Mail-Adresse.',
      UserFailureKind.invalidName =>
        'Bitte gib deinen Namen mit mindestens 2 Zeichen ein.',
      UserFailureKind.notFound => 'Nutzerprofil konnte nicht gefunden werden.',
      UserFailureKind.unknown =>
        'Nutzerprofil konnte nicht gespeichert werden.',
      UserFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um ein Nutzerprofil zu haben.',
    };
  }
}
