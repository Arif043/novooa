import 'runtime_endpoint.dart';

abstract interface class RuntimeEndpointStore {
  Future<RuntimeEndpoint?> load();
  Future<void> save(RuntimeEndpoint endpoint);
}
