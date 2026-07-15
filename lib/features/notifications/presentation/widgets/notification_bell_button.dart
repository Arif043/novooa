import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/app_notifications_cubit.dart';
import '../cubits/app_notifications_state.dart';
import 'notification_panel_dialog.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppNotificationsCubit, AppNotificationsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) {
        return IconButton(
          tooltip: 'Benachrichtigungen',
          icon: Badge.count(
            count: state.pendingCount,
            isLabelVisible: state.pendingCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => _showNotifications(context),
        );
      },
    );
  }

  Future<void> _showNotifications(BuildContext context) {
    final cubit = context.read<AppNotificationsCubit>();
    return showDialog<void>(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const NotificationDialog()),
    );
  }

  void _showMessage(BuildContext context, AppNotificationsState state) {
    final message = state.message;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
