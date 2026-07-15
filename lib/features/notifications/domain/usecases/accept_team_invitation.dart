import '../repositories/app_notification_repository.dart';

class AcceptTeamInvitation {
  const AcceptTeamInvitation(this._repository);

  final AppNotificationRepository _repository;

  Future<void> call(String notificationId) {
    return _repository.acceptTeamInvitation(notificationId);
  }
}
