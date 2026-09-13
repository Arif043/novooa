import '../entities/push_device.dart';

abstract interface class PushDeviceRepository {
  Future<void> save(PushDevice device);

  Future<void> remove({required String ownerId, required String token});
}
