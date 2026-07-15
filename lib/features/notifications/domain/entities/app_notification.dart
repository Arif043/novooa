enum AppNotificationType { teamInvitation, unknown }

enum AppNotificationStatus { pending, accepted, rejected, unknown }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.createdAt,
    this.teamId,
    this.teamName,
  });

  final String id;
  final AppNotificationType type;
  final AppNotificationStatus status;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? teamId;
  final String? teamName;

  bool get isPendingTeamInvitation {
    return type == AppNotificationType.teamInvitation &&
        status == AppNotificationStatus.pending;
  }
}
