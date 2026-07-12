import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_channel_grid.dart';
import 'create_communication_channel_dialog.dart';

class CommunicationSettingsTab extends StatelessWidget {
  const CommunicationSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<CommunicationCubit>()..load(),
      child: const _CommunicationView(),
    );
  }
}

class _CommunicationView extends StatelessWidget {
  const _CommunicationView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommunicationCubit, CommunicationState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: _showMessage,
      builder: (_, state) => _CommunicationBody(state: state),
    );
  }

  void _showMessage(BuildContext context, CommunicationState state) {
    final message = state.message;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CommunicationBody extends StatelessWidget {
  const _CommunicationBody({required this.state});

  final CommunicationState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommunicationHeader(isCreating: state.isCreating),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _CommunicationContent(state: state)),
      ],
    );
  }
}

class _CommunicationHeader extends StatelessWidget {
  const _CommunicationHeader({required this.isCreating});

  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Text('Kommunikation', style: Theme.of(context).textTheme.displayMedium),
        FilledButton.icon(
          onPressed: isCreating ? null : () => _openDialog(context),
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('Kanal hinzufügen'),
        ),
      ],
    );
  }

  Future<void> _openDialog(BuildContext context) async {
    final input = await showDialog(
      context: context,
      builder: (_) => const CreateCommunicationChannelDialog(),
    );
    if (input == null || !context.mounted) return;
    await context.read<CommunicationCubit>().create(input);
  }
}

class _CommunicationContent extends StatelessWidget {
  const _CommunicationContent({required this.state});

  final CommunicationState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      CommunicationLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      CommunicationLoadStatus.failure => _FailureState(message: state.message),
      CommunicationLoadStatus.ready when state.channels.isEmpty =>
        const _EmptyState(),
      CommunicationLoadStatus.ready => CommunicationChannelGrid(
        channels: state.channels,
      ),
    };
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Kanäle konnten nicht geladen werden.'),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: context.read<CommunicationCubit>().load,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Noch keine Kanäle',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Lege einen WhatsApp-, SMS- oder E-Mail-Kanal an.'),
        ],
      ),
    );
  }
}
