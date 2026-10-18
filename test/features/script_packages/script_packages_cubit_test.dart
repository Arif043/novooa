import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/script_packages/domain/entities/python_package.dart';
import 'package:syscat2/features/script_packages/domain/entities/script_package_environment.dart';
import 'package:syscat2/features/script_packages/domain/repositories/script_package_repository.dart';
import 'package:syscat2/features/script_packages/domain/usecases/install_script_packages.dart';
import 'package:syscat2/features/script_packages/domain/usecases/watch_script_package_environments.dart';
import 'package:syscat2/features/script_packages/presentation/cubits/script_packages_cubit.dart';
import 'package:syscat2/features/script_packages/presentation/cubits/script_packages_state.dart';

void main() {
  final six = [PythonPackage.parse('Six')!];

  ScriptPackagesCubit cubitWith(_Repository repository) => ScriptPackagesCubit(
    WatchScriptPackageEnvironments(repository),
    InstallScriptPackages(repository),
  );

  test('load übernimmt die Umgebungen der Runtime', () async {
    final repository = _Repository();
    final cubit = cubitWith(repository)..load();
    addTearDown(cubit.close);

    repository.environments.add([
      _ready(['six']),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, ScriptPackagesStatus.ready);
    expect(cubit.state.environmentFor(six)?.isReady, isTrue);
  });

  test(
    'install zeigt sofort „wird installiert“ und ruft die Runtime',
    () async {
      final repository = _Repository();
      final cubit = cubitWith(repository);
      addTearDown(cubit.close);

      await cubit.install(six);

      expect(repository.installed, [six]);
      expect(
        cubit.state.environmentFor(six)?.state,
        ScriptPackageEnvironmentState.installing,
      );
    },
  );

  test('scheitert der Aufruf, gilt die Installation als gescheitert', () async {
    final repository = _Repository(failInstall: true);
    final cubit = cubitWith(repository);
    addTearDown(cubit.close);

    await cubit.install(six);

    expect(
      cubit.state.environmentFor(six)?.state,
      ScriptPackageEnvironmentState.failed,
    );
  });

  test(
    'eine fertige Umgebung, die alle Imports abdeckt, ist wiederverwendbar',
    () {
      final state = ScriptPackagesState(
        status: ScriptPackagesStatus.ready,
        environments: [
          _ready(['numpy==2.1.0', 'pandas']),
        ],
      );

      expect(state.readyCovering({'pandas', 'numpy'}), hasLength(1));
      expect(state.readyCovering({'pandas', 'scipy'}), isEmpty);
    },
  );
}

ScriptPackageEnvironment _ready(List<String> packages) =>
    ScriptPackageEnvironment(
      packages: packages,
      state: ScriptPackageEnvironmentState.ready,
      sizeBytes: 10,
    );

class _Repository implements ScriptPackageRepository {
  _Repository({this.failInstall = false});

  final bool failInstall;
  final environments = StreamController<List<ScriptPackageEnvironment>>();
  final installed = <List<PythonPackage>>[];

  @override
  Stream<List<ScriptPackageEnvironment>> watchEnvironments() =>
      environments.stream;

  @override
  Future<void> install(List<PythonPackage> packages) async {
    installed.add(packages);
    if (failInstall) throw StateError('nicht erreichbar');
  }
}
