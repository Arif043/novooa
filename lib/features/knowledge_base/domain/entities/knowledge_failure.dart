enum KnowledgeFailureKind {
  unauthenticated,
  loadFailed,
  saveFailed,
  deleteFailed,
  invalidTitle,
}

class KnowledgeFailure {
  const KnowledgeFailure(this.kind);

  final KnowledgeFailureKind kind;

  String get message {
    return switch (kind) {
      KnowledgeFailureKind.unauthenticated =>
        'Du musst angemeldet sein, um die Wissensbasis zu nutzen.',
      KnowledgeFailureKind.loadFailed =>
        'Wissensbasis konnte nicht geladen werden.',
      KnowledgeFailureKind.saveFailed =>
        'Notiz konnte nicht gespeichert werden.',
      KnowledgeFailureKind.deleteFailed =>
        'Notiz konnte nicht gelöscht werden.',
      KnowledgeFailureKind.invalidTitle => 'Gib einen Namen für die Notiz ein.',
    };
  }
}
