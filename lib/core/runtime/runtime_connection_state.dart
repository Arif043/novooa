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

/// Eigener Schritt vor dem Passwort — über den regulären Port verlangt die
/// Runtime immer den Kopplungscode aus ihrem Start-Log (der code-freie
/// Loopback-Weg ist ein dokumentierter Operator-Fallback außerhalb der
/// App, siehe `docs/local-runtime.md`).
final class RuntimeConnectionNeedsSetupCode extends RuntimeConnectionState {
  const RuntimeConnectionNeedsSetupCode(
    this.endpoint, {
    this.errorMessage,
    this.addresses = const [],
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  /// Von der Runtime selbst ermittelte Adressen, unter denen andere Geräte
  /// sie erreichen. Werden angezeigt, nicht abgefragt.
  final List<String> addresses;
}

final class RuntimeConnectionNeedsPasswordSetup extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPasswordSetup(
    this.endpoint, {
    required this.code,
    this.errorMessage,
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  /// Im vorherigen Schritt eingegebener Kopplungscode — wird zusammen mit
  /// dem Passwort in einem einzigen `/v1/setup`-Aufruf verschickt.
  final String code;
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
