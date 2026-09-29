import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/runtime/workspace_capabilities.dart';
import 'package:syscat2/core/widgets/root_shell_scope.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_panel_dialog.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_state.dart';
import 'package:syscat2/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_assistant_plan_action_resolver.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';

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
      builder: (context, state) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Der KI-Agent ist (noch) ein Cloud-Feature — in Standalone ist
          // `AssistantCubit` nicht registriert. Ohne diese Prüfung würfe
          // `serviceLocator<AssistantCubit>()` in `_content()` einen
          // Registrierungsfehler mitten im Seitenpanel-Aufbau.
          if (serviceLocator<WorkspaceCapabilities>().assistant)
            _RailIconButton(
              tooltip: 'KI-Agent',
              icon: Icons.auto_awesome_outlined,
              selected: selectedPanel == TaskBuilderSidePanelKind.assistant,
              onPressed: () =>
                  onPanelSelected(TaskBuilderSidePanelKind.assistant),
            ),
          _RailIconButton(
            tooltip: 'Benachrichtigungen',
            selected: selectedPanel == TaskBuilderSidePanelKind.notifications,
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(left: false, child: _content(context)),
    );
  }

  Widget _content(BuildContext context) {
    return switch (panel) {
      TaskBuilderSidePanelKind.assistant => BlocProvider(
        create: (_) => serviceLocator<AssistantCubit>()
          ..setContext(
            const AssistantContext(
              area: AssistantArea.taskBuilder,
              route: '/tasks/builder',
            ),
          ),
        child: _assistantPanel(context),
      ),
      TaskBuilderSidePanelKind.notifications => NotificationPanel(
        onClose: onClose,
      ),
    };
  }

  Widget _assistantPanel(BuildContext context) {
    final cubit = _taskBuilderCubitOrNull(context);
    return AssistantPanel(
      onClose: onClose,
      planActionResolver: cubit == null
          ? null
          : TaskBuilderAssistantPlanActionResolver(cubit),
    );
  }

  TaskBuilderCubit? _taskBuilderCubitOrNull(BuildContext context) {
    final controller = RootShellScope.of(context);
    return controller.taskBuilderController is TaskBuilderCubit
        ? controller.taskBuilderController as TaskBuilderCubit
        : null;
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
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: selected
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: .12)
            : Colors.transparent,
      ),
      onPressed: onPressed,
      icon: child ?? Icon(icon),
    );
  }
}
