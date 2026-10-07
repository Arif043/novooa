enum RuntimeSessionFailureKind { runtimeUnavailable, unexpected }

/// Fehler beim Verwalten der Sitzungen einer Runtime.
class RuntimeSessionFailure {
  const RuntimeSessionFailure(this.kind);

  final RuntimeSessionFailureKind kind;

  String get message => switch (kind) {
    RuntimeSessionFailureKind.runtimeUnavailable =>
      'Die Runtime ist nicht erreichbar. Bitte versuche es erneut.',
    RuntimeSessionFailureKind.unexpected =>
      'Die anderen Sitzungen konnten nicht abgemeldet werden.',
  };
}
