import 'package:equatable/equatable.dart';

import '../../domain/entities/python_package.dart';
import '../../domain/entities/script_package_environment.dart';

enum ScriptPackagesStatus { loading, ready, failure }

class ScriptPackagesState extends Equatable {
  const ScriptPackagesState({
    this.status = ScriptPackagesStatus.loading,
    this.environments = const [],
  });

  final ScriptPackagesStatus status;
  final List<ScriptPackageEnvironment> environments;

  /// Die Umgebung genau dieser Paketliste; `null`, solange sie nicht
  /// installiert und auch nicht in Arbeit ist.
  ScriptPackageEnvironment? environmentFor(List<PythonPackage> packages) {
    final normalized = PythonPackage.normalizedList(packages);
    for (final environment in environments) {
      if (_sameList(environment.packages, normalized)) return environment;
    }
    return null;
  }

  /// Fertige Umgebungen, die alle [packageNames] enthalten — zum
  /// Wiederverwenden statt einer zweiten Installation.
  List<ScriptPackageEnvironment> readyCovering(Set<String> packageNames) {
    return [
      for (final environment in environments)
        if (environment.isReady &&
            packageNames.every(
              (name) => environment.packages.any(
                (package) => PythonPackage.parse(package)?.name == name,
              ),
            ))
          environment,
    ];
  }

  ScriptPackagesState copyWith({
    ScriptPackagesStatus? status,
    List<ScriptPackageEnvironment>? environments,
  }) {
    return ScriptPackagesState(
      status: status ?? this.status,
      environments: environments ?? this.environments,
    );
  }

  @override
  List<Object?> get props => [status, environments];
}

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
