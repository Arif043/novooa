import 'runtime_endpoint.dart';

sealed class RuntimeConnectionState {
  const RuntimeConnectionState();
}

final class RuntimeConnectionLoading extends RuntimeConnectionState {
  const RuntimeConnectionLoading();
}

final class RuntimeConnectionNeedsAddress extends RuntimeConnectionState {
  const RuntimeConnectionNeedsAddress(this.address, {this.errorMessage});

  final String address;
  final String? errorMessage;
}

final class RuntimeConnectionNeedsPassword extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPassword(this.endpoint, {this.errorMessage});

  final RuntimeEndpoint endpoint;
  final String? errorMessage;
}

final class RuntimeConnectionNeedsLicense extends RuntimeConnectionState {
  const RuntimeConnectionNeedsLicense(this.endpoint, {this.errorMessage});

  final RuntimeEndpoint endpoint;
  final String? errorMessage;
}

/// Zweiter Einrichtungsschritt nach der Lizenz: das Betreiber-Passwort.
/// Die Runtime verlangt als Nachweis den Lizenz-Token, mit dem sie
/// aktiviert wurde.
final class RuntimeConnectionNeedsPasswordSetup extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPasswordSetup(
    this.endpoint, {
    this.activationToken,
    this.requiresLicenseToken = true,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  /// Der im Lizenz-Schritt eingegebene Token — nur im Speicher. Fehlt er
  /// (z.B. nach einem App-Neustart), fragt das Formular ihn erneut ab.
  final String? activationToken;

  /// `false` nur bei einer Runtime im Entwicklungsmodus ohne echte Lizenz.
  final bool requiresLicenseToken;

  bool get needsTokenInput => requiresLicenseToken && activationToken == null;

  RuntimeConnectionNeedsPasswordSetup withError(String errorMessage) =>
      RuntimeConnectionNeedsPasswordSetup(
        endpoint,
        activationToken: activationToken,
        requiresLicenseToken: requiresLicenseToken,
        errorMessage: errorMessage,
      );
}

/// Web-Pendant zu `RuntimeConnectionNeedsAddress`: Es gibt nichts
/// einzugeben (die Origin ist die Adresse), also kein Adressfeld — nur
/// Fehlertext und ein erneuter Versuch.
final class RuntimeConnectionUnreachable extends RuntimeConnectionState {
  const RuntimeConnectionUnreachable(this.endpoint, {this.errorMessage});

  final RuntimeEndpoint endpoint;
  final String? errorMessage;
}

final class RuntimeConnectionConnecting extends RuntimeConnectionState {
  const RuntimeConnectionConnecting(this.address);

  final String address;
}

final class RuntimeConnectionReady extends RuntimeConnectionState {
  const RuntimeConnectionReady(this.endpoint);

  final RuntimeEndpoint endpoint;
}
