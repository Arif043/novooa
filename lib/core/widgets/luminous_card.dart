import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Karte der Luminous-Listenseiten (Zeitplan, Fähigkeiten): heller Grund, feiner Rahmen,
/// großzügiger Innenabstand.
class LuminousCard extends StatelessWidget {
  const LuminousCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.gutter),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

/// Symbol eines Eintrags auf einer zart getönten Kachel in der Akzentfarbe.
class LuminousIconBadge extends StatelessWidget {
  const LuminousIconBadge({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
        child: ExcludeSemantics(
          child: Icon(icon, color: colors.primary, size: AppSpacing.lg),
        ),
      ),
    );
  }
}

/// Kopf einer Karte: Symbol, Titel und Untertitel nebeneinander.
class LuminousCardHeading extends StatelessWidget {
  const LuminousCardHeading({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleMaxLines,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int? subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LuminousIconBadge(icon: icon),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: subtitleMaxLines,
                  overflow: subtitleMaxLines == null
                      ? null
                      : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
