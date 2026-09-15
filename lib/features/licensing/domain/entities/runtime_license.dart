class RuntimeLicenseKey {
  const RuntimeLicenseKey._(this.value);

  final String value;

  static RuntimeLicenseKey? tryCreate(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{12}$').hasMatch(normalized)) return null;
    return RuntimeLicenseKey._(normalized);
  }
}

enum RuntimeLicenseState { active, expired, notActivated }

class RuntimeLicenseStatus {
  const RuntimeLicenseStatus({required this.state, this.expiresAt});

  final RuntimeLicenseState state;
  final DateTime? expiresAt;

  bool get isActive => state == RuntimeLicenseState.active;
}

enum RuntimeLicenseFailureKind {
  invalidLicenseKey,
  runtimeUnavailable,
  activationRejected,
  releaseRejected,
  unexpected,
}

class RuntimeLicenseFailure {
  const RuntimeLicenseFailure(this.kind);

  final RuntimeLicenseFailureKind kind;

  String get message => switch (kind) {
    RuntimeLicenseFailureKind.invalidLicenseKey =>
      'Bitte gib den zwölfstelligen Lizenzschlüssel ein.',
    RuntimeLicenseFailureKind.runtimeUnavailable =>
      'Die Runtime ist nicht erreichbar.',
    RuntimeLicenseFailureKind.activationRejected =>
      'Der Lizenzschlüssel konnte nicht aktiviert werden.',
    RuntimeLicenseFailureKind.releaseRejected =>
      'Die Lizenz konnte nicht freigegeben werden.',
    RuntimeLicenseFailureKind.unexpected =>
      'Der Lizenzstatus konnte nicht geladen werden.',
  };
}
