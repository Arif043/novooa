import '../repositories/app_notification_repository.dart';

class RejectTeamInvitation {
  const RejectTeamInvitation(this._repository);

  final AppNotificationRepository _repository;

  Future<void> call(String notificationId) {
    return _repository.rejectTeamInvitation(notificationId);
  }
}
