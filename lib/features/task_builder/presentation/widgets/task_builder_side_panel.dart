import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_panel_dialog.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_state.dart';
import 'package:syscat2/features/notifications/presentation/widgets/notification_panel_dialog.dart';

enum TaskBuilderSidePanelKind { assistant, notifications }

class TaskBuilderSideRail extends StatelessWidget {
  const TaskBuilderSideRail({
    super.key,
    required this.selectedPanel,
    required this.onPanelSelected,
  });

  final TaskBuilderSidePanelKind? selectedPanel;
  final ValueChanged<TaskBuilderSidePanelKind> onPanelSelected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppNotificationsCubit, AppNotificationsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RailIconButton(
                tooltip: 'KI-Agent',
                icon: Icons.auto_awesome_outlined,
                selected: selectedPanel == TaskBuilderSidePanelKind.assistant,
                onPressed: () =>
                    onPanelSelected(TaskBuilderSidePanelKind.assistant),
              ),
              _RailIconButton(
                tooltip: 'Benachrichtigungen',
                selected:
                    selectedPanel == TaskBuilderSidePanelKind.notifications,
                onPressed: () =>
                    onPanelSelected(TaskBuilderSidePanelKind.notifications),
                child: Badge.count(
                  count: state.pendingCount,
                  isLabelVisible: state.pendingCount > 0,
                  child: const Icon(Icons.notifications_outlined),
                ),
              ),
            ],
          ),
        ),
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

class TaskBuilderSideDrawer extends StatelessWidget {
  const TaskBuilderSideDrawer({
    super.key,
    required this.panel,
    required this.onClose,
  });

  final TaskBuilderSidePanelKind panel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 10,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: SizedBox(width: 390, child: _content()),
      ),
    );
  }

  Widget _content() {
    return switch (panel) {
      TaskBuilderSidePanelKind.assistant => BlocProvider(
        create: (_) => serviceLocator<AssistantCubit>()
          ..setContext(
            const AssistantContext(
              area: AssistantArea.taskBuilder,
              route: '/tasks/builder',
            ),
          ),
        child: AssistantPanel(onClose: onClose),
      ),
      TaskBuilderSidePanelKind.notifications => NotificationPanel(
        onClose: onClose,
      ),
    };
  }
}

class _RailIconButton extends StatelessWidget {
  const _RailIconButton({
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    this.icon,
    this.child,
  });

  final String tooltip;
  final IconData? icon;
  final Widget? child;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
      ),
      onPressed: onPressed,
      icon: child ?? Icon(icon),
    );
  }
}
