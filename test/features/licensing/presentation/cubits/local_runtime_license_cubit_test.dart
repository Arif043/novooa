import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/licensing/domain/entities/local_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/repositories/local_runtime_license_repository.dart';
import 'package:syscat2/features/licensing/domain/usecases/activate_local_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/usecases/load_local_runtime_license_status.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_state.dart';

void main() {
  test(
    'sperrt die lokale Oberfläche bei einer nicht aktivierten Runtime',
    () async {
      final cubit = _cubit(_LicenseRepositoryFake());

      await cubit.load();

      expect(cubit.state, isA<LocalRuntimeLicenseNeedsActivation>());
      await cubit.close();
    },
  );

  test('schaltet nach erfolgreicher Aktivierung auf aktiv', () async {
    final cubit = _cubit(_LicenseRepositoryFake());
    await cubit.load();

    await cubit.activate('A3K9N7P2Q4R6');

    expect(cubit.state, isA<LocalRuntimeLicenseActive>());
    await cubit.close();
  });

  test('meldet einen zu kurzen Lizenzschlüssel ohne Gateway-Aufruf', () async {
    final repository = _LicenseRepositoryFake();
    final cubit = _cubit(repository);

    await cubit.activate('kurz');

    expect(cubit.state, isA<LocalRuntimeLicenseFailureState>());
    expect(repository.activationCalls, 0);
    await cubit.close();
  });
}

LocalRuntimeLicenseCubit _cubit(LocalRuntimeLicenseRepository repository) {
  return LocalRuntimeLicenseCubit(
    loadStatus: LoadLocalRuntimeLicenseStatus(repository),
    activateLicense: ActivateLocalRuntimeLicense(repository),
  );
}

class _LicenseRepositoryFake implements LocalRuntimeLicenseRepository {
  int activationCalls = 0;

  @override
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  activate(LocalRuntimeLicenseKey licenseKey) async {
    activationCalls++;
    return const Success(
      LocalRuntimeLicenseStatus(state: LocalRuntimeLicenseState.active),
    );
  }

  @override
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  loadStatus() async {
    return const Success(
      LocalRuntimeLicenseStatus(state: LocalRuntimeLicenseState.notActivated),
    );
  }
}
