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

final class RuntimeConnectionNeedsPasswordSetup extends RuntimeConnectionState {
  const RuntimeConnectionNeedsPasswordSetup(
    this.endpoint, {
    this.errorMessage,
    this.requiresCode = false,
    this.addresses = const [],
  });

  final RuntimeEndpoint endpoint;
  final String? errorMessage;

  /// Über den regulären Port verlangt die Runtime den Kopplungscode aus
  /// ihrem Start-Log — die Oberfläche blendet das Feld nur dann ein.
  final bool requiresCode;

  /// Von der Runtime selbst ermittelte Adressen, unter denen andere Geräte
  /// sie erreichen. Werden angezeigt, nicht abgefragt.
  final List<String> addresses;
}

final class RuntimeConnectionConnecting extends RuntimeConnectionState {
  const RuntimeConnectionConnecting(this.address);

  final String address;
}

final class RuntimeConnectionReady extends RuntimeConnectionState {
  const RuntimeConnectionReady(this.endpoint);

  final RuntimeEndpoint endpoint;
}
