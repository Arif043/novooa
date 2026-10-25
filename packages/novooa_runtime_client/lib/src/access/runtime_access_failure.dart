/// Warum Verbindung, Anmeldung oder Einrichtung scheiterten. Das Paket
/// liefert nur die Art; den Text formuliert jede App selbst in ihrer Sprache.
enum RuntimeAccessFailureKind {
  invalidAddress,
  savedAddressUnreadable,
  unreachable,

  /// Die Domain antwortet, aber ihr Zertifikat ist ungültig.
  certificateInvalid,
  invalidCredentials,
  invalidInvitation,
  licenseTokenMismatch,
  adminNotFound,
  invalidPassword,
  notLicensed,
  tooManyAttempts,
  noToken,

  /// Unerwarteter HTTP-Status; siehe [RuntimeAccessFailure.statusCode].
  failedWithStatus,
  sessionEnded,
  signOutFailed,
  activationFailed,
  activationTimeout,
  setupFailed,
  setupAlreadyDone,

  /// Die Runtime erklärt den Grund selbst; siehe [RuntimeAccessFailure.detail].
  rejectedByRuntime,

  /// Ein Fehler im Client nach der Prüfung, etwa beim Speichern des Tokens;
  /// [RuntimeAccessFailure.detail] nennt die Ursache.
  unexpected,
}

class RuntimeAccessFailure implements Exception {
  const RuntimeAccessFailure(this.kind, {this.statusCode, this.detail});

  final RuntimeAccessFailureKind kind;
  final int? statusCode;
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is RuntimeAccessFailure &&
      other.kind == kind &&
      other.statusCode == statusCode &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, statusCode, detail);

  @override
  String toString() => 'RuntimeAccessFailure($kind, $statusCode, $detail)';
}
