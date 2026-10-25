import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/licensing/domain/entities/runtime_license.dart';
import 'package:syscat2/features/licensing/domain/repositories/runtime_license_repository.dart';
import 'package:syscat2/features/licensing/domain/usecases/activate_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/usecases/load_runtime_license_status.dart';
import 'package:syscat2/features/licensing/domain/usecases/release_runtime_license.dart';
import 'package:syscat2/features/licensing/presentation/cubits/runtime_license_cubit.dart';
import 'package:syscat2/root_page.dart';

void main() {
  testWidgets('zeigt vor der Aktivierung keine App-Shell', (tester) async {
    final cubit = _licenseCubit();
    await cubit.load();

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: RootPage(location: '/tasks', child: SizedBox.shrink()),
        ),
      ),
    );

    expect(find.text('Lizenz aktivieren'), findsWidgets);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });
}

RuntimeLicenseCubit _licenseCubit() {
  final repository = _InactiveLicenseRepository();
  return RuntimeLicenseCubit(
    loadStatus: LoadRuntimeLicenseStatus(repository),
    activateLicense: ActivateRuntimeLicense(repository),
    releaseLicense: ReleaseRuntimeLicense(repository),
  );
}

class _InactiveLicenseRepository implements RuntimeLicenseRepository {
  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> activate(
    RuntimeLicenseKey licenseKey,
  ) async {
    return const Success(
      RuntimeLicenseStatus(state: RuntimeLicenseState.notActivated),
    );
  }

  @override
  Future<Result<RuntimeLicenseStatus, RuntimeLicenseFailure>> release() async {
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
