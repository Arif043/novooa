import '../repositories/notification_device_repository.dart';

class UnregisterNotificationDevice {
  const UnregisterNotificationDevice(this._repository);

  final NotificationDeviceRepository _repository;

  Future<void> call({required String userId, required String token}) {
    return _repository.deleteToken(userId: userId, token: token);
  }
}
