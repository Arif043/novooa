/// Ein fehlgeschlagener TLS-Handshake bedeutet etwas völlig anderes als eine
/// nicht erreichbare Runtime: Der Dienst antwortet, nur sein Zertifikat ist
/// ungültig. Beides in eine Meldung zu werfen, schickt den Betreiber in die
/// falsche Richtung — er sucht den Netzwerkfehler, während der Reverse Proxy
/// das eigentliche Problem hat.
///
/// Die Erkennung läuft bewusst über den Fehlertext statt über einen
/// `dart:io`-Import: Diese Datei wird auch für die Cloud-Variante im Web
/// kompiliert, wo `dart:io` nicht verfügbar ist. `toString()` erfasst dabei
/// zugleich in `WorkspaceConnectionException` eingepackte Ursachen.
bool isCertificateFailure(Object error) {
  final text = error.toString();
  return text.contains('HandshakeException') ||
      text.contains('CertificateException');
}

String runtimeConnectionFailureMessageFor(
  Object error, {
  required bool isSecure,
}) {
  if (isSecure && isCertificateFailure(error)) {
    return 'Das Zertifikat dieser Domain ist ungültig — abgelaufen, '
        'selbstsigniert oder auf einen anderen Namen ausgestellt. Prüfe den '
        'Reverse Proxy, der die Domain bedient. Für einen Zugriff ohne '
        'Zertifikat verwende die IP-Adresse der Runtime.';
  }
  return 'Die Runtime konnte unter dieser Adresse nicht erreicht werden.';
}
