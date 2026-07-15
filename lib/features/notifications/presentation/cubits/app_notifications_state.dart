import '../../domain/entities/app_notification.dart';

enum AppNotificationsStatus { loading, ready, failure }

class AppNotificationsState {
  const AppNotificationsState({
    this.status = AppNotificationsStatus.loading,
    this.notifications = const [],
    this.processingId,
    this.message,
  });

  final AppNotificationsStatus status;
  final List<AppNotification> notifications;
  final String? processingId;
  final String? message;

  int get pendingCount {
    return notifications.where(_isPending).length;
  }

  bool _isPending(AppNotification item) {
    return item.isPendingTeamInvitation || item.isPendingTaskRunApproval;
  }

  AppNotificationsState copyWith({
    AppNotificationsStatus? status,
    List<AppNotification>? notifications,
    String? processingId,
    String? message,
  }) {
    return AppNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      processingId: processingId,
      message: message,
    );
  }
}
