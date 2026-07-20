import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

class WhatsappBusinessOnboardingNotice extends StatelessWidget {
  const WhatsappBusinessOnboardingNotice({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('WhatsApp Business', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Bestehende WhatsApp-Business-Nummern werden über die '
              'WhatsApp Business Platform verbunden. Die Nummer ist erst '
              'nach Verifizierung und Migration aktiv.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: accepted,
              onChanged: (value) => onChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Ich kann die Nummer verifizieren.'),
            ),
          ],
        ),
      ),
    );
  }
}
