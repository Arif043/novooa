import '../entities/python_package.dart';
import '../repositories/script_package_repository.dart';

class InstallScriptPackages {
  const InstallScriptPackages(this._repository);

  final ScriptPackageRepository _repository;

  Future<void> call(List<PythonPackage> packages) =>
      _repository.install(packages);
}
