import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Kopf der Luminous-Listenseiten: großer Titel links, Hauptaktion rechts (bricht bei wenig
/// Platz um), darunter Untertitel und optional eine Zusammenfassung wie „1 aktiv · 0 pausiert“.
class LuminousPageHeader extends StatelessWidget {
  const LuminousPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.action,
    this.summary,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: theme.textTheme.headlineLarge),
              ),
              action,
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (summary case final text?) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(text, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
