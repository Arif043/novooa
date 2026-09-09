import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/widgets/root_side_menu_sections.dart';
import 'package:syscat2/features/licensing/domain/entities/local_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/repositories/local_runtime_license_repository.dart';
import 'package:syscat2/features/licensing/domain/usecases/activate_local_runtime_license.dart';
import 'package:syscat2/features/licensing/domain/usecases/load_local_runtime_license_status.dart';
import 'package:syscat2/features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import 'package:syscat2/root_page.dart';

void main() {
  testWidgets('zeigt lokal vor der Aktivierung keine App-Shell', (
    tester,
  ) async {
    final cubit = _licenseCubit();
    await cubit.load();

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: RootPage(
            location: '/tasks',
            isLocal: true,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('Lokale Runtime aktivieren'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('verzichtet im lokalen Seitenmenü auf das Cloud-Profil', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SideMenuHeader(showCurrentUserProfile: false)),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}

LocalRuntimeLicenseCubit _licenseCubit() {
  final repository = _InactiveLicenseRepository();
  return LocalRuntimeLicenseCubit(
    loadStatus: LoadLocalRuntimeLicenseStatus(repository),
    activateLicense: ActivateLocalRuntimeLicense(repository),
  );
}

class _InactiveLicenseRepository implements LocalRuntimeLicenseRepository {
  @override
  Future<Result<LocalRuntimeLicenseStatus, LocalRuntimeLicenseFailure>>
  activate(LocalRuntimeLicenseKey licenseKey) async {
    return const Success(
      LocalRuntimeLicenseStatus(state: LocalRuntimeLicenseState.notActivated),
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
