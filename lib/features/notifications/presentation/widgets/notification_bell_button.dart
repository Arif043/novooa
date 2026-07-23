import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../../../activity/presentation/cubits/activity_cubit.dart';
import '../../../activity/presentation/widgets/approval_review_dialog.dart';
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

  Future<void> _showNotifications(BuildContext context) async {
    final cubit = context.read<AppNotificationsCubit>();
    final run = await showDialog<TaskRun>(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: cubit, child: const NotificationDialog()),
    );
    if (!context.mounted || run == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => serviceLocator<ActivityCubit>(),
        child: ApprovalReviewDialog(run: run),
      ),
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
