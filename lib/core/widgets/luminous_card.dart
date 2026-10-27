import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Karte der Luminous-Listenseiten (Zeitplan, Fähigkeiten, Mitarbeiter): heller Grund, feiner
/// Rahmen, großzügiger Innenabstand. Mit [onTap] ist die ganze Karte antippbar.
class LuminousCard extends StatelessWidget {
  const LuminousCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Material statt DecoratedBox, damit die Tipp-Welle über dem Kartengrund sichtbar ist.
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(AppSpacing.gutter),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
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

/// Kopf einer Karte: [leading] (meist [LuminousIconBadge], bei Mitarbeitern ihr Avatar),
/// Titel und Untertitel nebeneinander.
class LuminousCardHeading extends StatelessWidget {
  const LuminousCardHeading({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.subtitleMaxLines,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final int? subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        leading,
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
