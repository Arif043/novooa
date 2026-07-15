import '../entities/notification_device_token.dart';

abstract interface class NotificationDeviceRepository {
  Future<void> saveToken(NotificationDeviceToken token);

  Future<void> deleteToken({required String userId, required String token});
}
