enum PasswordFailure {
  invalidPassword,
  signInRequired,
  recentLoginRequired,
  network,
  rateLimited,
  unexpected;

  String get message => switch (this) {
    invalidPassword =>
      'Nutze ein Passwort mit mindestens 6 und höchstens 1000 Zeichen. Beachte auch die Passwortregeln deines Kontos.',
    signInRequired => 'Bitte melde dich erneut an, um dein Passwort zu ändern.',
    recentLoginRequired =>
      'Deine Anmeldung liegt zu lange zurück. Melde dich erneut an und setze anschließend dein neues Passwort.',
    network =>
      'Das Passwort konnte nicht gespeichert werden. Prüfe deine Verbindung und versuche es erneut.',
    rateLimited => 'Zu viele Versuche. Warte kurz und versuche es erneut.',
    unexpected =>
      'Das Passwort konnte nicht gespeichert werden. Bitte versuche es erneut.',
  };
}
