part of 'assistant_panel_dialog.dart';

class _AssistantMessageBubble extends StatelessWidget {
  const _AssistantMessageBubble({
    required this.message,
    required this.planActionResolver,
    required this.messageBodyBuilder,
  });

  final AssistantMessage message;
  final AssistantPlanActionResolver? planActionResolver;
  final AssistantMessageBodyBuilder? messageBodyBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AssistantMessageRole.user;
    final bubble = DecoratedBox(
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _MessageContent(
          message: message,
          planActionResolver: planActionResolver,
          bodyBuilder: isUser ? null : messageBodyBuilder,
        ),
      ),
    );
    if (isUser) return Align(alignment: Alignment.centerRight, child: bubble);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NooviImage(pose: NooviPose.present, size: 32),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: bubble),
      ],
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.planActionResolver,
    required this.bodyBuilder,
  });

  final AssistantMessage message;
  final AssistantPlanActionResolver? planActionResolver;
  final AssistantMessageBodyBuilder? bodyBuilder;

  @override
  Widget build(BuildContext context) {
    final actions = planActionResolver?.actionsFor(message) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          bodyBuilder?.call(context, message.text) ??
              Text(message.text, style: Theme.of(context).textTheme.bodyMedium),
        AssistantMessageSources(sources: message.urlSources),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AssistantActionPlan(actions: actions),
        ],
      ],
    );
  }
}

class _AssistantLoadingBubble extends StatelessWidget {
  const _AssistantLoadingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: NooviThinking(size: 48),
    );
  }
}

class _AssistantInput extends StatelessWidget {
  const _AssistantInput({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssistantCubit, AssistantState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.errorMessage != null)
            _AssistantError(text: state.errorMessage!),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submit(context),
            decoration: InputDecoration(
              hintText: LocaleKeys.ui_frage_zum_aktuellen_bereich_stellen.tr(),
              suffixIcon: IconButton(
                tooltip: LocaleKeys.ui_senden.tr(),
                onPressed: state.isLoading ? null : () => _submit(context),
                icon: const Icon(Icons.send_outlined),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit(BuildContext context) {
    final text = controller.text;
    controller.clear();
    context.read<AssistantCubit>().ask(text);
  }
}

class _AssistantError extends StatelessWidget {
  const _AssistantError({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: TextStyle(color: theme.colorScheme.error)),
    );
  }
}
