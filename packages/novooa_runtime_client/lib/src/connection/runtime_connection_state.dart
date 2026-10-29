import '../access/runtime_access_failure.dart';
import '../endpoint/runtime_endpoint.dart';

sealed class RuntimeConnectionState {
  const RuntimeConnectionState();
}

final class RuntimeConnectionLoading extends RuntimeConnectionState {
  const RuntimeConnectionLoading();
}

final class RuntimeConnectionNeedsAddress extends RuntimeConnectionState {
  const RuntimeConnectionNeedsAddress(this.address, {this.failure});

  final String address;
  final RuntimeAccessFailure? failure;
}

/// Wie man sich anmeldet: mit Konto, mit einem Einladungscode (eigenes
/// Passwort setzen) oder über den Notzugang mit dem Lizenz-Token.
enum RuntimeSignInMode { password, invitation, recovery }

final class RuntimeConnectionNeedsPassword extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPassword(
    this.endpoint, {
    this.mode = RuntimeSignInMode.password,
    this.failure,
  });

  final RuntimeEndpoint endpoint;
  final RuntimeSignInMode mode;
  final RuntimeAccessFailure? failure;
}

final class RuntimeConnectionNeedsLicense extends RuntimeConnectionState {
  const RuntimeConnectionNeedsLicense(this.endpoint, {this.failure});

  final RuntimeEndpoint endpoint;
  final RuntimeAccessFailure? failure;
}

/// Zweiter Einrichtungsschritt nach der Lizenz: das erste Admin-Konto.
/// Die Runtime verlangt als Nachweis den Lizenz-Token, mit dem sie
/// aktiviert wurde.
final class RuntimeConnectionNeedsPasswordSetup extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPasswordSetup(
    this.endpoint, {
    this.activationToken,
    this.failure,
  });

  final RuntimeEndpoint endpoint;
  final RuntimeAccessFailure? failure;

  /// Der im Lizenz-Schritt eingegebene Token — nur im Speicher. Fehlt er
  /// (z.B. nach einem App-Neustart), fragt das Formular ihn erneut ab.
  final String? activationToken;

  bool get needsTokenInput => activationToken == null;

  RuntimeConnectionNeedsPasswordSetup withFailure(
    RuntimeAccessFailure failure,
  ) => RuntimeConnectionNeedsPasswordSetup(
    endpoint,
    activationToken: activationToken,
    failure: failure,
  );
}

/// Web-Pendant zu `RuntimeConnectionNeedsAddress`: Es gibt nichts
/// einzugeben (die Origin ist die Adresse), also kein Adressfeld — nur
/// Fehlertext und ein erneuter Versuch.
final class RuntimeConnectionUnreachable extends RuntimeConnectionState {
  const RuntimeConnectionUnreachable(this.endpoint, {this.failure});

  final RuntimeEndpoint endpoint;
  final RuntimeAccessFailure? failure;
}

final class RuntimeConnectionConnecting extends RuntimeConnectionState {
  const RuntimeConnectionConnecting(this.address);

  final String address;
}

final class RuntimeConnectionReady extends RuntimeConnectionState {
  const RuntimeConnectionReady(this.endpoint);

  final RuntimeEndpoint endpoint;
}
