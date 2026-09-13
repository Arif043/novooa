import '../repositories/push_device_repository.dart';

class UnregisterPushDevice {
  const UnregisterPushDevice(this._repository);

  final PushDeviceRepository _repository;

  Future<void> call({required String ownerId, required String token}) {
    return _repository.remove(ownerId: ownerId, token: token);
  }
}
