import '../entities/plugin_activation.dart';
import '../repositories/plugin_repository.dart';

class WatchPlugins {
  const WatchPlugins(this._repository);

  final PluginRepository _repository;

  Stream<List<PluginActivation>> call() => _repository.watchPlugins();
}
