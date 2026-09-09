import 'dart:async';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/app_notification_repository.dart';

class LocalAppNotificationRepository implements AppNotificationRepository {
  const LocalAppNotificationRepository();

  @override
  Future<void> acceptTeamInvitation(String notificationId) async {}

  @override
  Future<void> rejectTeamInvitation(String notificationId) async {}

  @override
  Stream<List<AppNotification>> watchNotifications() => Stream.value(const []);
}
