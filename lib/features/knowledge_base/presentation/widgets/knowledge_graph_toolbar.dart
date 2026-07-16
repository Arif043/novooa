import 'package:flutter/material.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

class KnowledgeGraphToolbar extends StatelessWidget {
  const KnowledgeGraphToolbar({super.key, required this.onResetView});

  final VoidCallback onResetView;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.86),
        border: Border.all(
          color: colorScheme.onInverseSurface.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 18,
              color: colorScheme.onInverseSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Graph',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onInverseSurface.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Ansicht zurücksetzen',
              onPressed: onResetView,
              icon: const Icon(Icons.center_focus_strong),
              color: colorScheme.onInverseSurface.withValues(alpha: 0.78),
            ),
          ],
        ),
      ),
    );
  }
}
