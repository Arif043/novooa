import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/assistant_message.dart';
import '../cubits/assistant_cubit.dart';
import '../cubits/assistant_state.dart';

part 'assistant_panel_dialog_parts.dart';

class AssistantPanelDialog extends StatefulWidget {
  const AssistantPanelDialog({super.key});

  @override
  State<AssistantPanelDialog> createState() => _AssistantPanelDialogState();
}

class _AssistantPanelDialogState extends State<AssistantPanelDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _AssistantHeader(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _AssistantMessages(theme: theme)),
              const SizedBox(height: AppSpacing.md),
              _AssistantInput(controller: _controller),
            ],
          ),
        ),
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
        Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('KI-Agent', style: theme.textTheme.titleLarge)),
        IconButton(
          tooltip: 'Schließen',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _AssistantMessages extends StatelessWidget {
  const _AssistantMessages({required this.theme});

  final ThemeData theme;

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
    return _AssistantMessageBubble(message: state.messages[index]);
  }
}

class _AssistantEmptyState extends StatelessWidget {
  const _AssistantEmptyState({required this.contextLabel});

  final String contextLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'Frag mich etwas zu "$contextLabel".',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
