import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/widgets/noovi/noovi_image.dart';
import 'package:syscat2/core/widgets/noovi/noovi_pose.dart';
import 'package:syscat2/core/widgets/noovi/noovi_thinking.dart';

import '../../domain/entities/assistant_message.dart';
import '../agent/assistant_plan_action_resolver.dart';
import '../cubits/assistant_cubit.dart';
import '../cubits/assistant_state.dart';
import 'assistant_action_plan.dart';
import 'assistant_message_sources.dart';

part 'assistant_panel_dialog_parts.dart';

class AssistantPanelDialog extends StatelessWidget {
  const AssistantPanelDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
          child: CupertinoPopupSurface(
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: AssistantPanel(onClose: () => Navigator.of(context).pop()),
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantPanel extends StatefulWidget {
  const AssistantPanel({
    super.key,
    required this.onClose,
    this.planActionResolver,
  });

  final VoidCallback onClose;
  final AssistantPlanActionResolver? planActionResolver;

  @override
  State<AssistantPanel> createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _AssistantHeader(onClose: widget.onClose),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _AssistantMessages(
              theme: theme,
              planActionResolver: widget.planActionResolver,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _AssistantInput(controller: _controller),
        ],
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const NooviImage(pose: NooviPose.wave, size: 32),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            LocaleKeys.ui_ki_agent.tr(),
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton(
          tooltip: LocaleKeys.ui_schliessen.tr(),
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _AssistantMessages extends StatelessWidget {
  const _AssistantMessages({
    required this.theme,
    required this.planActionResolver,
  });

  final ThemeData theme;
  final AssistantPlanActionResolver? planActionResolver;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantCubit, AssistantState>(
      builder: (context, state) {
        if (state.messages.isEmpty && !state.isLoading) {
          return _AssistantEmptyState(contextLabel: state.context.label);
        }
        return ListView.separated(
          itemCount: state.messages.length + (state.isLoading ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _itemFor(state, index),
        );
      },
    );
  }

  Widget _itemFor(AssistantState state, int index) {
    if (index == state.messages.length) return const _AssistantLoadingBubble();
    return _AssistantMessageBubble(
      message: state.messages[index],
      planActionResolver: planActionResolver,
    );
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.contextLabel});

  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NooviImage(pose: NooviPose.wave, size: 112),
            const SizedBox(height: AppSpacing.md),
            Text(
              LocaleKeys.ui_ask_about_context.tr(
                namedArgs: {'context': contextLabel},
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
