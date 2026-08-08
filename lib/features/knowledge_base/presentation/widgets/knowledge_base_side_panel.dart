import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/assistant/presentation/widgets/assistant_panel_dialog.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_state.dart';
import 'package:syscat2/features/notifications/presentation/widgets/notification_panel.dart';

import '../cubits/knowledge_base_cubit.dart';
import '../cubits/knowledge_base_state.dart';
import 'knowledge_base_graph_panel.dart';

enum KnowledgeBaseSidePanelKind { assistant, notifications, properties }

class KnowledgeBaseSideRail extends StatelessWidget {
  const KnowledgeBaseSideRail({
    super.key,
    required this.selectedPanel,
    required this.onPanelSelected,
  });

  final KnowledgeBaseSidePanelKind? selectedPanel;
  final ValueChanged<KnowledgeBaseSidePanelKind> onPanelSelected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppNotificationsCubit, AppNotificationsState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RailIconButton(
            tooltip: 'KI-Agent',
            icon: Icons.auto_awesome_outlined,
            selected: selectedPanel == KnowledgeBaseSidePanelKind.assistant,
            onPressed: () =>
                onPanelSelected(KnowledgeBaseSidePanelKind.assistant),
          ),
          _RailIconButton(
            tooltip: 'Benachrichtigungen',
            selected: selectedPanel == KnowledgeBaseSidePanelKind.notifications,
            onPressed: () =>
                onPanelSelected(KnowledgeBaseSidePanelKind.notifications),
            child: Badge.count(
              count: state.pendingCount,
              isLabelVisible: state.pendingCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          _RailIconButton(
            tooltip: 'Eigenschaften',
            icon: Icons.tune_outlined,
            selected: selectedPanel == KnowledgeBaseSidePanelKind.properties,
            onPressed: () =>
                onPanelSelected(KnowledgeBaseSidePanelKind.properties),
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

class KnowledgeBaseSideDrawer extends StatelessWidget {
  const KnowledgeBaseSideDrawer({
    super.key,
    required this.panel,
    required this.onClose,
    required this.knowledgeBaseCubit,
  });

  final KnowledgeBaseSidePanelKind panel;
  final VoidCallback onClose;
  final KnowledgeBaseCubit knowledgeBaseCubit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(left: false, child: _content()),
    );
  }

  Widget _content() {
    return switch (panel) {
      KnowledgeBaseSidePanelKind.assistant => BlocProvider(
        create: (_) => serviceLocator<AssistantCubit>()
          ..setContext(
            const AssistantContext(
              area: AssistantArea.knowledgeBase,
              route: '/knowledge-base',
            ),
          ),
        child: AssistantPanel(onClose: onClose),
      ),
      KnowledgeBaseSidePanelKind.notifications => NotificationPanel(
        onClose: onClose,
      ),
      KnowledgeBaseSidePanelKind.properties => BlocProvider.value(
        value: knowledgeBaseCubit,
        child: BlocBuilder<KnowledgeBaseCubit, KnowledgeBaseState>(
          builder: (context, state) => KnowledgeBaseGraphPanel(state: state),
        ),
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
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Colors.transparent,
      ),
      onPressed: onPressed,
      icon: child ?? Icon(icon),
    );
  }
}
