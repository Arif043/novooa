import '../entities/notification_device_token.dart';
import '../repositories/notification_device_repository.dart';

class RegisterNotificationDevice {
  const RegisterNotificationDevice(this._repository);

  final NotificationDeviceRepository _repository;

  Future<void> call(NotificationDeviceToken token) {
    return _repository.saveToken(token);
  }
}
