enum RuntimeSessionFailureKind { runtimeUnavailable, notFound, unexpected }

/// Fehler beim Verwalten der Sitzungen einer Runtime; Texte entstehen in der
/// Oberfläche.
class RuntimeSessionFailure {
  const RuntimeSessionFailure(this.kind);

  final RuntimeSessionFailureKind kind;
}
