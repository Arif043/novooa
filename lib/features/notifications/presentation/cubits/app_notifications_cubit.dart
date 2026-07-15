import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/accept_team_invitation.dart';
import '../../domain/usecases/reject_team_invitation.dart';
import '../../domain/usecases/watch_app_notifications.dart';
import 'app_notifications_state.dart';

class AppNotificationsCubit extends Cubit<AppNotificationsState> {
  AppNotificationsCubit(
    this._watchNotifications,
    this._acceptInvitation,
    this._rejectInvitation,
  ) : super(const AppNotificationsState());

  final WatchAppNotifications _watchNotifications;
  final AcceptTeamInvitation _acceptInvitation;
  final RejectTeamInvitation _rejectInvitation;
  StreamSubscription<List<AppNotification>>? _subscription;

  void load() {
    _subscription?.cancel();
    _subscription = _watchNotifications().listen(
      _emitNotifications,
      onError: (_) => _emitFailure(),
    );
  }

  Future<void> accept(String notificationId) async {
    await _handleAction(
      notificationId,
      _acceptInvitation.call,
      'Einladung angenommen.',
    );
  }

  Future<void> reject(String notificationId) async {
    await _handleAction(
      notificationId,
      _rejectInvitation.call,
      'Einladung abgelehnt.',
    );
  }

  void _emitNotifications(List<AppNotification> notifications) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: AppNotificationsStatus.ready,
        notifications: notifications,
      ),
    );
  }

  Future<void> _handleAction(
    String notificationId,
    Future<void> Function(String) action,
    String message,
  ) async {
    emit(state.copyWith(processingId: notificationId));
    try {
      await action(notificationId);
      emit(state.copyWith(processingId: null, message: message));
    } catch (_) {
      emit(
        state.copyWith(
          processingId: null,
          message: 'Aktion konnte nicht ausgeführt werden.',
        ),
      );
    }
  }

  void _emitFailure() {
    emit(
      state.copyWith(
        status: AppNotificationsStatus.failure,
        message: 'Benachrichtigungen konnten nicht geladen werden.',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
