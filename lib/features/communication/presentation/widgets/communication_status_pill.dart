import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';

import '../../domain/entities/communication_channel.dart';
import 'communication_labels.dart';

/// Status als Punkt plus Text. Die Farbe allein trägt nichts: Das Wort steht
/// immer dabei.
class CommunicationStatusPill extends StatelessWidget {
  const CommunicationStatusPill({super.key, required this.channel});

  final CommunicationChannel channel;

  @override
  Widget build(BuildContext context) {
    final tone = _toneFor(context, channel.status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: AppSpacing.sm, color: tone),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                channel.statusLabel,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneFor(BuildContext context, CommunicationChannelStatus status) {
    return switch (status) {
      CommunicationChannelStatus.active => SyscatTheme.success,
      CommunicationChannelStatus.setupRequired ||
      CommunicationChannelStatus.pendingVerification => SyscatTheme.warning,
      CommunicationChannelStatus.reauthorizationRequired => Theme.of(
        context,
      ).colorScheme.error,
      CommunicationChannelStatus.disabled => SyscatTheme.textMuted,
    };
  }
}
