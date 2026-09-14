import 'package:bloc/bloc.dart';

import '../../domain/entities/runtime_license.dart';
import '../../domain/usecases/activate_runtime_license.dart';
import '../../domain/usecases/load_runtime_license_status.dart';
import 'runtime_license_state.dart';

class RuntimeLicenseCubit extends Cubit<RuntimeLicenseCubitState> {
  RuntimeLicenseCubit({required this.loadStatus, required this.activateLicense})
    : super(const RuntimeLicenseLoading());

  final LoadRuntimeLicenseStatus loadStatus;
  final ActivateRuntimeLicense activateLicense;

  Future<void> load() async {
    emit(const RuntimeLicenseLoading());
    final statusOrFailure = await loadStatus();
    if (isClosed) return;
    statusOrFailure.when(_emitStatus, _emitFailure);
  }

  Future<void> activate(String rawLicenseKey) async {
    final licenseKey = RuntimeLicenseKey.tryCreate(rawLicenseKey);
    if (licenseKey == null) return _emitInvalidLicenseKey();
    emit(const RuntimeLicenseActivating());
    final statusOrFailure = await activateLicense(licenseKey);
    if (isClosed) return;
    statusOrFailure.when(_emitStatus, _emitFailure);
  }

  void _emitStatus(RuntimeLicenseStatus status) {
    if (status.isActive) return emit(RuntimeLicenseActive(status));
    emit(RuntimeLicenseNeedsActivation(expiredAt: status.expiresAt));
  }

  void _emitInvalidLicenseKey() {
    _emitFailure(
      const RuntimeLicenseFailure(RuntimeLicenseFailureKind.invalidLicenseKey),
    );
  }

  void _emitFailure(RuntimeLicenseFailure failure) {
    emit(RuntimeLicenseFailureState(failure));
  }
}
