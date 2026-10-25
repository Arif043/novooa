import 'runtime_endpoint.dart';

abstract interface class RuntimeEndpointStore {
  Future<RuntimeEndpoint?> load();
  Future<void> save(RuntimeEndpoint endpoint);

  /// Verwirft die gespeicherte Adresse — Teil des vollständigen Resets beim
  /// Abmelden (siehe `RuntimeConnectionCubit.signOut`).
  Future<void> clear();
}
