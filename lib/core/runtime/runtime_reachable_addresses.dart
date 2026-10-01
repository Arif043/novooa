import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Zeigt, unter welchen Adressen andere Geräte diese Runtime erreichen —
/// von ihr selbst ermittelt. Bewusst keine Eingabe: Ein abgetippter Wert
/// würde bei jedem DHCP-Wechsel still falsch.
class RuntimeReachableAddresses extends StatelessWidget {
  const RuntimeReachableAddresses({required this.addresses, super.key});

  final List<String> addresses;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Von anderen Geräten erreichbar unter',
          style: textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final address in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: SelectableText(address, style: textTheme.bodyMedium),
          ),
      ],
    );
  }
}
