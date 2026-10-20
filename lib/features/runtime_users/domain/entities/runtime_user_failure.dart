/// Warum eine Aktion an Konten scheiterte. [kind] wählt die Meldung in der
/// Oberfläche; [serverMessage] erklärt Eingabefehler, die die Runtime prüft.
enum RuntimeUserFailureKind {
  invalidInput,
  loginNameTaken,
  userLimitReached,
  lastAdmin,
  ownAccount,
  workspaceOwner,
  notFound,
  adminRequired,
  unavailable,
}

class RuntimeUserFailure {
  const RuntimeUserFailure(this.kind, {this.serverMessage});

  final RuntimeUserFailureKind kind;
  final String? serverMessage;
}
