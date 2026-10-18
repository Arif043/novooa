import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

/// Leiste über dem Graphen; mit gewählter Notiz nennt sie, wie viele Notizen
/// ein Prompt mit dieser Notiz im Kontext hat.
class KnowledgeGraphToolbar extends StatelessWidget {
  const KnowledgeGraphToolbar({
    super.key,
    required this.onResetView,
    this.contextNoteCount,
  });

  final VoidCallback onResetView;
  final int? contextNoteCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.86),
        border: Border.all(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              LocaleKeys.knowledge_graph_title.tr(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.76),
              ),
            ),
            if (contextNoteCount case final int count) ...[
              const SizedBox(width: AppSpacing.sm),
              _ContextNoteCount(count: count),
            ],
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: LocaleKeys.knowledge_graph_reset_view.tr(),
              onPressed: onResetView,
              icon: const Icon(Icons.center_focus_strong),
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextNoteCount extends StatelessWidget {
  const _ContextNoteCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: LocaleKeys.knowledge_graph_context_hint.tr(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            LocaleKeys.knowledge_graph_context_notes.tr(
              namedArgs: {'count': '$count'},
            ),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.primary),
          ),
        ),
      ),
    );
  }
}
