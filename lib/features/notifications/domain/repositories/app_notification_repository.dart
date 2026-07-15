import '../entities/app_notification.dart';

abstract interface class AppNotificationRepository {
  Stream<List<AppNotification>> watchNotifications();

  Future<void> acceptTeamInvitation(String notificationId);

  Future<void> rejectTeamInvitation(String notificationId);
}
