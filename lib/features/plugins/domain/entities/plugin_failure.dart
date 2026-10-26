enum PluginFailureKind {
  runtimeUnavailable,
  adminRequired,
  notFound,
  unexpected,
}

/// Fehler beim Laden oder Schalten von Plugins; Texte entstehen in der
/// Oberfläche.
class PluginFailure {
  const PluginFailure(this.kind);

  final PluginFailureKind kind;
}
