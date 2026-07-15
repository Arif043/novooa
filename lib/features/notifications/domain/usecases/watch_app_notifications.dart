import '../entities/app_notification.dart';
import '../repositories/app_notification_repository.dart';

class WatchAppNotifications {
  const WatchAppNotifications(this._repository);

  final AppNotificationRepository _repository;

  Stream<List<AppNotification>> call() {
    return _repository.watchNotifications();
  }
}
