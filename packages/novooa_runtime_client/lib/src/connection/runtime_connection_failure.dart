import '../access/runtime_access_failure.dart';

/// Ein fehlgeschlagener TLS-Handshake bedeutet etwas völlig anderes als eine
/// nicht erreichbare Runtime: Der Dienst antwortet, nur sein Zertifikat ist
/// ungültig. Beides in eine Meldung zu werfen, schickt den Betreiber in die
/// falsche Richtung — er sucht den Netzwerkfehler, während der Reverse Proxy
/// das eigentliche Problem hat.
///
/// Die Erkennung läuft bewusst über den Fehlertext statt über einen
/// `dart:io`-Import: Diese Datei wird auch für das Web kompiliert, wo
/// `dart:io` nicht verfügbar ist. `toString()` erfasst dabei
/// zugleich in `WorkspaceConnectionException` eingepackte Ursachen.
bool isCertificateFailure(Object error) {
  final text = error.toString();
  return text.contains('HandshakeException') ||
      text.contains('CertificateException');
}

RuntimeAccessFailure runtimeConnectionFailureFor(
  Object error, {
  required bool isSecure,
}) => RuntimeAccessFailure(
  isSecure && isCertificateFailure(error)
      ? RuntimeAccessFailureKind.certificateInvalid
      : RuntimeAccessFailureKind.unreachable,
);
