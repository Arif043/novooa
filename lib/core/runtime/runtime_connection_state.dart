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

final class RuntimeConnectionConnecting extends RuntimeConnectionState {
  const RuntimeConnectionConnecting(this.address);

  final String address;
}

final class RuntimeConnectionReady extends RuntimeConnectionState {
  const RuntimeConnectionReady(this.endpoint);

  final RuntimeEndpoint endpoint;
}
