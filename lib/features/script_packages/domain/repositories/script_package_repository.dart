import '../entities/python_package.dart';
import '../entities/script_package_environment.dart';

/// Paketumgebungen der Runtime für Script-Bausteine.
abstract interface class ScriptPackageRepository {
  /// Alle bekannten Umgebungen; aktualisiert sich bei jeder Änderung.
  Stream<List<ScriptPackageEnvironment>> watchEnvironments();

  /// Startet die Installation; der Fortschritt kommt über [watchEnvironments].
  Future<void> install(List<PythonPackage> packages);
}
