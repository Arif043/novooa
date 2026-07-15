import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_notification.dart';
import '../cubits/app_notifications_cubit.dart';
import '../cubits/app_notifications_state.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppNotificationsCubit, AppNotificationsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) {
        return PopupMenuButton<void>(
          tooltip: 'Benachrichtigungen',
          icon: Badge.count(
            count: state.pendingCount,
            isLabelVisible: state.pendingCount > 0,
            child: const Icon(Icons.notifications_outlined),
          ),
          itemBuilder: (_) => [_contentItem(context, state)],
        );
      },
    );
  }

  PopupMenuItem<void> _contentItem(
    BuildContext context,
    AppNotificationsState state,
  ) {
    return PopupMenuItem<void>(
      enabled: false,
      padding: EdgeInsets.zero,
      child: SizedBox(width: 360, child: _NotificationPanel(state: state)),
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

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel({required this.state});

  final AppNotificationsState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: switch (state.status) {
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
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.state});

  final AppNotificationsState state;

  @override
  Widget build(BuildContext context) {
    if (state.notifications.isEmpty) {
      return const Text('Keine Benachrichtigungen.');
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
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
          if (item.isPendingTeamInvitation)
            _InvitationActions(item: item, state: state),
        ],
      ),
    );
  }
}

class _InvitationActions extends StatelessWidget {
  const _InvitationActions({required this.item, required this.state});

  final AppNotification item;
  final AppNotificationsState state;

  @override
  Widget build(BuildContext context) {
    final isProcessing = state.processingId == item.id;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          TextButton(
            onPressed: isProcessing ? null : () => _reject(context),
            child: const Text('Ablehnen'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: isProcessing ? null : () => _accept(context),
            child: isProcessing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Annehmen'),
          ),
        ],
      ),
    );
  }

  void _accept(BuildContext context) {
    context.read<AppNotificationsCubit>().accept(item.id);
  }

  void _reject(BuildContext context) {
    context.read<AppNotificationsCubit>().reject(item.id);
  }
}
