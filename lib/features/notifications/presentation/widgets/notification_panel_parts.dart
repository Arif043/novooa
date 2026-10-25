part of 'notification_panel.dart';

class _ApprovalAction extends StatelessWidget {
  const _ApprovalAction({
    required this.item,
    required this.onApprovalRequested,
  });

  final AppNotification item;
  final Future<void> Function(BuildContext context, TaskRun run)
  onApprovalRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: FilledButton(
        onPressed: () => _openReview(context),
        child: Text(_label),
      ),
    );
  }

  void _openReview(BuildContext context) {
    final run = item.taskRun;
    if (run == null) return;
    onApprovalRequested(context, run);
  }

  String get _label {
    final run = item.taskRun;
    if (run?.requiresDialogInput == true) return 'Formular öffnen';
    return 'Prüfen';
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
