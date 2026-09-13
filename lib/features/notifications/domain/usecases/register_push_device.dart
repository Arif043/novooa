import '../entities/push_device.dart';
import '../repositories/push_device_repository.dart';

class RegisterPushDevice {
  const RegisterPushDevice(this._repository);

  final PushDeviceRepository _repository;

  Future<void> call(PushDevice device) {
    return _repository.save(device);
  }
}
