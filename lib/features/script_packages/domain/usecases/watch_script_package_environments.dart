import '../entities/script_package_environment.dart';
import '../repositories/script_package_repository.dart';

class WatchScriptPackageEnvironments {
  const WatchScriptPackageEnvironments(this._repository);

  final ScriptPackageRepository _repository;

  Stream<List<ScriptPackageEnvironment>> call() =>
      _repository.watchEnvironments();
}
