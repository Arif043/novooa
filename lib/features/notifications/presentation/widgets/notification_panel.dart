import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios_overlays.dart';
import '../../../activity/domain/entities/task_run.dart';
import '../../../activity/presentation/cubits/activity_cubit.dart';
import '../../../activity/presentation/widgets/task_run_interaction_dialog.dart';
import '../../infrastructure/services/fcm_bootstrapper.dart';
import '../../domain/entities/app_notification.dart';
import '../cubits/app_notifications_cubit.dart';
import '../cubits/app_notifications_state.dart';

part 'notification_panel_parts.dart';

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppNotificationsCubit, AppNotificationsState>(
      builder: (context, state) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _NotificationHeader(onClose: onClose),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _NotificationContent(
                state: state,
                onApprovalRequested: _openApproval,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openApproval(BuildContext context, TaskRun run) {
    return showIosDialog<void>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => serviceLocator<ActivityCubit>(),
        child: TaskRunInteractionDialog(run: run),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({required this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text('Benachrichtigungen', style: theme.textTheme.titleLarge),
        ),
        IconButton(
          tooltip: 'Push-Benachrichtigungen aktivieren',
          onPressed: () => _requestPushNotifications(context),
          icon: const Icon(Icons.notifications_active_outlined),
        ),
        if (onClose != null)
          IconButton(
            tooltip: 'Schließen',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }

  Future<void> _requestPushNotifications(BuildContext context) async {
    await serviceLocator<FcmBootstrapper>().requestPermissionAndRegister();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Push-Benachrichtigungen wurden angefragt.'),
      ),
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({
    required this.state,
    required this.onApprovalRequested,
  });

  final AppNotificationsState state;
  final Future<void> Function(BuildContext context, TaskRun run)
  onApprovalRequested;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      AppNotificationsStatus.loading => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      ),
      AppNotificationsStatus.failure => const Text(
        'Benachrichtigungen konnten nicht geladen werden.',
      ),
      AppNotificationsStatus.ready => _NotificationList(
        state: state,
        onApprovalRequested: onApprovalRequested,
      ),
    };
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.state,
    required this.onApprovalRequested,
  });

  final AppNotificationsState state;
  final Future<void> Function(BuildContext context, TaskRun run)
  onApprovalRequested;

  @override
  Widget build(BuildContext context) {
    if (state.notifications.isEmpty) {
      return const Align(
        alignment: Alignment.topLeft,
        child: Text('Keine Benachrichtigungen.'),
      );
    }
    return ListView(
      children: state.notifications
          .map(
            (item) => _NotificationTile(
              item: item,
              state: state,
              onApprovalRequested: onApprovalRequested,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.state,
    required this.onApprovalRequested,
  });

  final AppNotification item;
  final AppNotificationsState state;
  final Future<void> Function(BuildContext context, TaskRun run)
  onApprovalRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(item.message),
          if (item.isPendingTaskRunApproval)
            _ApprovalAction(
              item: item,
              onApprovalRequested: onApprovalRequested,
            ),
          if (item.isPendingTeamInvitation)
            _InvitationActions(item: item, state: state),
        ],
      ),
    );
  }
}
