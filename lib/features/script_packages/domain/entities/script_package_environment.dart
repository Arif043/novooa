import 'package:equatable/equatable.dart';

enum ScriptPackageEnvironmentState { installing, failed, ready }

/// Warum eine Installation scheiterte; der Text dazu kommt aus der Übersetzung.
/// [notLoadable]: installiert, aber die Probe im Script-Container konnte die
/// Pakete nicht laden (fehlende Systembibliothek, zu langsamer Import).
enum ScriptPackageInstallProblem {
  notFound,
  noWheel,
  tooLarge,
  notLoadable,
  failed,
}

/// Eine Paketumgebung der Runtime: installiert, in Arbeit oder gescheitert.
/// [packages] ist die normalisierte Liste (`PythonPackage.normalizedList`).
class ScriptPackageEnvironment extends Equatable {
  const ScriptPackageEnvironment({
    required this.packages,
    required this.state,
    this.problem,
    this.detail,
    this.sizeBytes,
  });

  final List<String> packages;
  final ScriptPackageEnvironmentState state;
  final ScriptPackageInstallProblem? problem;

  /// Auszug aus der Ausgabe des Installers, für die Fehlersuche.
  final String? detail;
  final int? sizeBytes;

  bool get isReady => state == ScriptPackageEnvironmentState.ready;

  @override
  List<Object?> get props => [packages, state, problem, detail, sizeBytes];
}
