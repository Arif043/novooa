import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/widgets/root_shell_scope.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_panel_dialog.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_state.dart';
import 'package:syscat2/features/notifications/presentation/widgets/notification_panel.dart';
import 'package:syscat2/features/task_builder/presentation/agent/task_builder_assistant_plan_action_resolver.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';

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
          _RailIconButton(
            tooltip: LocaleKeys.ui_ki_agent.tr(),
            selected: selectedPanel == TaskBuilderSidePanelKind.assistant,
            onPressed: () =>
                onPanelSelected(TaskBuilderSidePanelKind.assistant),
            child: const NooviImage(pose: NooviPose.wave, size: 28),
          ),
          _RailIconButton(
            tooltip: LocaleKeys.ui_benachrichtigungen.tr(),
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
            AssistantContext(
              area: AssistantArea.taskBuilder,
              route: '/tasks/builder',
              languageCode: context.locale.languageCode,
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
    required this.child,
  });

  final String tooltip;
  final Widget child;
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
      icon: child,
    );
  }
}
