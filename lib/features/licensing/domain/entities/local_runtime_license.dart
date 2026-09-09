class LocalRuntimeLicenseKey {
  const LocalRuntimeLicenseKey._(this.value);

  final String value;

  static LocalRuntimeLicenseKey? tryCreate(String value) {
    final normalized = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (!RegExp(r'^[A-HJ-NP-Z2-9]{12}$').hasMatch(normalized)) return null;
    return LocalRuntimeLicenseKey._(normalized);
  }
}

enum LocalRuntimeLicenseState { active, expired, notActivated }

class LocalRuntimeLicenseStatus {
  const LocalRuntimeLicenseStatus({required this.state, this.expiresAt});

  final LocalRuntimeLicenseState state;
  final DateTime? expiresAt;

  bool get isActive => state == LocalRuntimeLicenseState.active;
}

enum LocalRuntimeLicenseFailureKind {
  invalidLicenseKey,
  runtimeUnavailable,
  activationRejected,
  unexpected,
}

class LocalRuntimeLicenseFailure {
  const LocalRuntimeLicenseFailure(this.kind);

  final LocalRuntimeLicenseFailureKind kind;

  String get message => switch (kind) {
    LocalRuntimeLicenseFailureKind.invalidLicenseKey =>
      'Bitte gib den zwölfstelligen Lizenzschlüssel ein.',
    LocalRuntimeLicenseFailureKind.runtimeUnavailable =>
      'Die lokale Runtime ist nicht erreichbar.',
    LocalRuntimeLicenseFailureKind.activationRejected =>
      'Der Lizenzschlüssel konnte nicht aktiviert werden.',
    LocalRuntimeLicenseFailureKind.unexpected =>
      'Der Lizenzstatus konnte nicht geladen werden.',
  };
}
