import 'runtime_endpoint.dart';

abstract interface class RuntimeAvailability {
  Future<void> check(RuntimeEndpoint endpoint);
}
