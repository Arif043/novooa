part of 'assistant_panel_dialog.dart';

class _AssistantMessageBubble extends StatelessWidget {
  const _AssistantMessageBubble({
    required this.message,
    required this.taskBuilderCubit,
  });

  final AssistantMessage message;
  final TaskBuilderCubit? taskBuilderCubit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == AssistantMessageRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
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
            taskBuilderCubit: taskBuilderCubit,
          ),
        ),
      ),
    );
  }
}

class _MessageContent extends StatelessWidget {
  const _MessageContent({
    required this.message,
    required this.taskBuilderCubit,
  });

  final AssistantMessage message;
  final TaskBuilderCubit? taskBuilderCubit;

  @override
  Widget build(BuildContext context) {
    final commands = message.taskCommands;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text.isNotEmpty)
          Text(message.text, style: Theme.of(context).textTheme.bodyMedium),
        if (commands.isNotEmpty && taskBuilderCubit != null) ...[
          const SizedBox(height: AppSpacing.md),
          AssistantTaskCommandPlan(
            commands: commands,
            taskBuilderCubit: taskBuilderCubit!,
          ),
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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
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
              hintText: 'Frage zum aktuellen Bereich stellen',
              suffixIcon: IconButton(
                tooltip: 'Senden',
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
