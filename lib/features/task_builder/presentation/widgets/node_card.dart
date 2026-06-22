import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';

/// Karte eines Bausteins im vertikalen Flow.
///
/// Layout: links primitive-Pill, Titel + Beschreibung darunter;
/// rechts Drag-Handle und Delete-Icon. Ausgewählter Knoten trägt einen
/// orangenen 2 px-Border.
///
/// Der erste Knoten (`isStart == true`) bekommt keinen Delete / Drag —
/// er ist der Einsprungspunkt des Flows.
class NodeCard extends StatelessWidget {
  const NodeCard({
    super.key,
    required this.node,
    required this.selected,
    required this.isStart,
    required this.onTap,
    required this.onDelete,
  });

  final WorkflowNode node;
  final bool selected;
  final bool isStart;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? SyscatTheme.primaryOrangeDark
        : SyscatTheme.borderLight;
    final background = selected
        ? SyscatTheme.primaryOrangeHover.withValues(alpha: 0.35)
        : SyscatTheme.glassSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: '${node.title} auswählen',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _PrimitivePill(label: node.primitive.label)),
                    if (!isStart) ...[
                      _CardIconButton(
                        tooltip: 'Baustein entfernen',
                        icon: Icons.delete_outline,
                        onPressed: onDelete,
                        selected: selected,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const _DragHandle(),
                    ] else
                      _CountBadge(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  node.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  node.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimitivePill extends StatelessWidget {
  const _PrimitivePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SyscatTheme.primaryOrangeLightest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: SyscatTheme.primaryOrangeDark,
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    required this.selected,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      style: IconButton.styleFrom(
        foregroundColor: selected
            ? SyscatTheme.primaryOrangeDark
            : SyscatTheme.textHint,
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Icon(
        Icons.drag_indicator,
        size: 18,
        color: SyscatTheme.textHint,
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '5 Bausteine',
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}