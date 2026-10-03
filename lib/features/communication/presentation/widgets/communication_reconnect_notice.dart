import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Hinweis auf einer Karte, deren Anmeldung abgelaufen ist; nur erneutes
/// Verbinden hilft.
class CommunicationReconnectNotice extends StatelessWidget {
  const CommunicationReconnectNotice({super.key, required this.onReconnect});

  final VoidCallback onReconnect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Die Anmeldung ist abgelaufen. Verbinde das Postfach neu, '
              'damit wieder E-Mails ankommen.',
            ),
            const SizedBox(height: AppSpacing.sm),
            Tooltip(
              message: 'Postfach neu verbinden',
              child: FilledButton.tonalIcon(
                onPressed: onReconnect,
                icon: const Icon(Icons.link),
                label: const Text('Neu verbinden'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
