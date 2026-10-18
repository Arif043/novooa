import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/python_package.dart';
import '../../domain/entities/script_package_environment.dart';
import '../../domain/usecases/install_script_packages.dart';
import '../../domain/usecases/watch_script_package_environments.dart';
import 'script_packages_state.dart';

class ScriptPackagesCubit extends Cubit<ScriptPackagesState> {
  ScriptPackagesCubit(this._watch, this._install)
    : super(const ScriptPackagesState());

  final WatchScriptPackageEnvironments _watch;
  final InstallScriptPackages _install;
  StreamSubscription<List<ScriptPackageEnvironment>>? _subscription;

  void load() {
    _subscription?.cancel();
    emit(const ScriptPackagesState());
    _subscription = _watch().listen(
      (environments) => emit(
        state.copyWith(
          status: ScriptPackagesStatus.ready,
          environments: environments,
        ),
      ),
      onError: (_, _) =>
          emit(state.copyWith(status: ScriptPackagesStatus.failure)),
    );
  }

  /// Startet die Installation; bis der Server antwortet, steht sie schon als
  /// „wird installiert“ da. Scheitert der Aufruf, gilt sie als gescheitert.
  Future<void> install(List<PythonPackage> packages) async {
    _replace(packages, ScriptPackageEnvironmentState.installing);
    try {
      await _install(packages);
    } catch (_) {
      _replace(
        packages,
        ScriptPackageEnvironmentState.failed,
        ScriptPackageInstallProblem.failed,
      );
    }
  }

  void _replace(
    List<PythonPackage> packages,
    ScriptPackageEnvironmentState environmentState, [
    ScriptPackageInstallProblem? problem,
  ]) {
    final normalized = PythonPackage.normalizedList(packages);
    final others = state.environments.where(
      (environment) => state.environmentFor(packages) != environment,
    );
    emit(
      state.copyWith(
        environments: [
          ...others,
          ScriptPackageEnvironment(
            packages: normalized,
            state: environmentState,
            problem: problem,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
