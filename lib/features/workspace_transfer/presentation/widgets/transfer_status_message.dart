import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

enum TransferMessageTone { progress, success, error }

/// Einheitliche Rückmeldung für laufende, erfolgreiche und fehlgeschlagene
/// Vorgänge. Wird Screenreadern als Live-Region angekündigt.
class TransferStatusMessage extends StatelessWidget {
  const TransferStatusMessage({
    super.key,
    required this.tone,
    required this.message,
  });

  final TransferMessageTone tone;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = switch (tone) {
      TransferMessageTone.progress => colorScheme.onSurfaceVariant,
      TransferMessageTone.success => colorScheme.primary,
      TransferMessageTone.error => colorScheme.error,
    };
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tone == TransferMessageTone.progress) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(message, style: textTheme.bodyMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}
