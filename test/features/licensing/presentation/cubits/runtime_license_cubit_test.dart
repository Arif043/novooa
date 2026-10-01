import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/licensing/domain/entities/runtime_license.dart';
import 'package:syscat2/features/licensing/domain/repositories/runtime_license_repository.dart';
import 'package:syscat2/features/licensing/domain/usecases/activate_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/usecases/load_runtime_license_status.dart';
import 'package:syscat2/features/licensing/domain/usecases/release_runtime_license.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_state.dart';

void main() {
  test(
    'sperrt die lokale Oberfläche bei einer nicht aktivierten Runtime',
    () async {
      final cubit = _cubit(_LicenseRepositoryFake());

      await cubit.load();

      expect(cubit.state, isA<RuntimeLicenseNeedsActivation>());
      await cubit.close();
    },
  );

  test('schaltet nach erfolgreicher Aktivierung auf aktiv', () async {
    final cubit = _cubit(_LicenseRepositoryFake());
    await cubit.load();

    await cubit.activate('A3K9N7P2Q4R6T8W5');

    expect(cubit.state, isA<RuntimeLicenseActive>());
    await cubit.close();
  });

  test('gibt eine aktive Lizenz frei', () async {
    final repository = _LicenseRepositoryFake();
    final cubit = _cubit(repository);

    await cubit.release();

    expect(cubit.state, isA<RuntimeLicenseNeedsActivation>());
    expect(repository.releaseCalls, 1);
    await cubit.close();
  });

  test('meldet einen zu kurzen Lizenzschlüssel ohne Gateway-Aufruf', () async {
    final repository = _LicenseRepositoryFake();
    final cubit = _cubit(repository);

    await cubit.activate('kurz');

    expect(cubit.state, isA<RuntimeLicenseFailureState>());
    expect(repository.activationCalls, 0);
    await cubit.close();
  });
}

RuntimeLicenseCubit _cubit(RuntimeLicenseRepository repository) {
  return RuntimeLicenseCubit(
    loadStatus: LoadRuntimeLicenseStatus(repository),
    activateLicense: ActivateRuntimeLicense(repository),
    releaseLicense: ReleaseRuntimeLicense(repository),
  );
}

class _LicenseRepositoryFake implements RuntimeLicenseRepository {
  int activationCalls = 0;
  int releaseCalls = 0;

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> activate(
    RuntimeLicenseKey licenseKey,
  ) async {
    activationCalls++;
    return const Success(
      RuntimeLicenseStatus(state: RuntimeLicenseState.active),
    );
  }

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> release() async {
    releaseCalls++;
    return const Success(
      RuntimeLicenseStatus(state: RuntimeLicenseState.notActivated),
    );
  }

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>>
  loadStatus() async {
    return const Success(
      RuntimeLicenseStatus(state: RuntimeLicenseState.notActivated),
    );
  }
}
