import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/communication_channel.dart';
import 'communication_labels.dart';
import 'communication_provider_logo.dart';
import 'communication_reconnect_notice.dart';
import 'communication_status_pill.dart';

class CommunicationChannelTile extends StatelessWidget {
  const CommunicationChannelTile({
    super.key,
    required this.channel,
    this.onReconnect,
  });

  final CommunicationChannel channel;

  /// Nur gesetzt, wenn die Anmeldung des Postfachs abgelaufen ist.
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(channel: channel),
            const SizedBox(height: AppSpacing.md),
            _Details(channel: channel),
            if (onReconnect != null) ...[
              const SizedBox(height: AppSpacing.md),
              CommunicationReconnectNotice(onReconnect: onReconnect!),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.channel});

  final CommunicationChannel channel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: CommunicationProviderLogo(
              provider: channel.provider,
              fallbackIcon: channel.icon,
            ),
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.channel});

  final CommunicationChannel channel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channel.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(channel.address, overflow: TextOverflow.ellipsis),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${channel.providerLabel} · ${channel.directionLabel}',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        CommunicationStatusPill(channel: channel),
      ],
    );
  }
}
