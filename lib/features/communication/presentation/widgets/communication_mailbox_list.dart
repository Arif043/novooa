import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/communication_channel.dart';
import '../cubits/communication_cubit.dart';
import '../cubits/communication_state.dart';
import 'communication_labels.dart';
import 'communication_provider_logo.dart';
import 'communication_status_pill.dart';

/// Erste Seite des Postfach-Dialogs: die verbundenen Postfächer als Liste,
/// als letzter Eintrag die Möglichkeit, ein weiteres zu verbinden.
class CommunicationMailboxList extends StatelessWidget {
  const CommunicationMailboxList({
    super.key,
    required this.onAddMailbox,
    required this.onReconnect,
  });

  final VoidCallback onAddMailbox;
  final ValueChanged<CommunicationChannel> onReconnect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunicationCubit, CommunicationState>(
      builder: (context, state) => switch (state.status) {
        CommunicationLoadStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        CommunicationLoadStatus.failure when state.channels.isEmpty =>
          _LoadFailure(onRetry: context.read<CommunicationCubit>().load),
        _ => _list(state.channels.where((c) => c.isConnectorBacked)),
      },
    );
  }

  Widget _list(Iterable<CommunicationChannel> mailboxes) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      children: [
        for (final mailbox in mailboxes) ...[
          _MailboxRow(mailbox: mailbox, onReconnect: onReconnect),
          const Divider(height: 1),
        ],
        ListTile(
          minVerticalPadding: AppSpacing.md,
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Weiteres Postfach verbinden'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onAddMailbox,
        ),
      ],
    );
  }
}

class _MailboxRow extends StatelessWidget {
  const _MailboxRow({required this.mailbox, required this.onReconnect});

  final CommunicationChannel mailbox;
  final ValueChanged<CommunicationChannel> onReconnect;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: AppSpacing.md,
      leading: CommunicationProviderLogo(
        provider: mailbox.provider,
        fallbackIcon: mailbox.icon,
        size: AppSpacing.lg + AppSpacing.sm,
      ),
      title: Text(mailbox.label, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mailbox.address, overflow: TextOverflow.ellipsis),
            const SizedBox(height: AppSpacing.sm),
            CommunicationStatusPill(channel: mailbox),
          ],
        ),
      ),
      trailing: mailbox.needsReconnection
          ? TextButton(
              onPressed: () => onReconnect(mailbox),
              child: const Text('Neu verbinden'),
            )
          : null,
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Die Postfächer konnten nicht geladen werden.'),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Erneut versuchen')),
        ],
      ),
    );
  }
}
