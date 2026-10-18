import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import 'workflow_canvas_layout.dart';

/// Einfügestelle am Ende eines Pfads („Hier anschließen“), optional mit
/// Fortsetzungs-Label darüber.
class CanvasPathInsertion extends StatelessWidget {
  const CanvasPathInsertion({
    super.key,
    required this.entry,
    required this.targeted,
    required this.onPressed,
  });
  final CanvasEntry entry;
  final bool targeted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (entry.continuationLabel case final String label) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          if (entry.canInsert) const SizedBox(height: 12),
        ],
        if (entry.canInsert)
          Expanded(
            child: OutlinedButton.icon(
              key: ValueKey('path-insertion-${entry.id}'),
              style: OutlinedButton.styleFrom(
                backgroundColor: targeted
                    ? colors.primaryContainer.withValues(alpha: .12)
                    : colors.surface.withValues(alpha: .8),
                side: BorderSide(
                  color: targeted ? colors.primary : colors.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.add),
              label: Text(LocaleKeys.task_builder_canvas_connect_here.tr()),
            ),
          ),
      ],
    );
  }
}
