import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../activity/presentation/cubits/activity_cubit.dart';
import '../../../activity/presentation/widgets/approval_review_dialog.dart';
import '../../domain/entities/app_notification.dart';
import '../cubits/app_notifications_cubit.dart';
import '../cubits/app_notifications_state.dart';

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
        child: BlocBuilder<AppNotificationsCubit, AppNotificationsState>(
          builder: (context, state) => _NotificationPanel(state: state),
        ),
      ),
    );
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
          if (item.isPendingTaskRunApproval) _ApprovalAction(item: item),
          if (item.isPendingTeamInvitation)
            _InvitationActions(item: item, state: state),
        ],
      ),
    );
  }
}

class _ApprovalAction extends StatelessWidget {
  const _ApprovalAction({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: FilledButton(
        onPressed: () => _openReview(context),
        child: const Text('Prüfen'),
      ),
    );
  }

  Future<void> _openReview(BuildContext context) async {
    final run = item.taskRun;
    if (run == null) return;
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    if (!rootContext.mounted) return;
    await showDialog<void>(
      context: rootContext,
      builder: (_) => BlocProvider(
        create: (_) => serviceLocator<ActivityCubit>(),
        child: ApprovalReviewDialog(run: run),
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
