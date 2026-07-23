import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_notification.dart';
import '../cubits/app_notifications_cubit.dart';
import '../cubits/app_notifications_state.dart';

part 'notification_panel_dialog_parts.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(
        top: kToolbarHeight + AppSpacing.sm,
        right: AppSpacing.md,
        left: AppSpacing.md,
      ),
      child: SizedBox(
        width: 360,
        height: 520,
        child: const NotificationPanel(),
      ),
    );
  }
}

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
            Expanded(child: _NotificationContent(state: state)),
          ],
        ),
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
        if (onClose != null)
          IconButton(
            tooltip: 'Schließen',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
      ],
    );
  }
}

class _NotificationContent extends StatelessWidget {
  const _NotificationContent({required this.state});

  final AppNotificationsState state;

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
      AppNotificationsStatus.ready => _NotificationList(state: state),
    };
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.state});

  final AppNotificationsState state;

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
          .map((item) => _NotificationTile(item: item, state: state))
          .toList(growable: false),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.state});

  final AppNotification item;
  final AppNotificationsState state;

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
          if (item.isPendingTaskRunApproval) _ApprovalAction(item: item),
          if (item.isPendingTeamInvitation)
            _InvitationActions(item: item, state: state),
        ],
      ),
    );
  }
}
