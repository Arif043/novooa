import 'package:flutter/material.dart';

import '../../domain/entities/workflow_node.dart';
import '../cubits/workflow_primitive_labels.dart';

/// Darstellung eines Bausteins auf der Leinwand: Icon, Titel und ID.
/// Wird für die Node selbst und für ihr Drag-Feedback genutzt.
class CompactNodeCard extends StatelessWidget {
  const CompactNodeCard({
    super.key,
    required this.node,
    required this.leading,
    this.selected = false,
    this.highlighted = false,
    this.elevation,
    this.onTap,
  });

  final WorkflowNode node;
  final Widget leading;
  final bool selected;
  final bool highlighted;
  final double? elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: elevation ?? (selected ? 4 : 1),
      shadowColor: colors.shadow.withValues(alpha: .12),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected || highlighted
              ? colors.primaryContainer
              : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('compact-node-${node.id.value}'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(child: _NodeHeadline(node: node)),
              // Kein „Baustein verbinden“-Button: Er hängte bedingungslos
              // einen weiteren Nachfolger an jeden Baustein, auch an
              // nicht-verzweigende Primitives — der Runner führt einen so
              // entstandenen zweiten Zweig ohne Zusammenführung sequenziell
              // mit aus (kein Guard in WorkflowGraph.addNode). Der erste
              // Nachfolger bleibt über den Platzhalter „+ Baustein hier
              // verbinden“ möglich.
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeHeadline extends StatelessWidget {
  const _NodeHeadline({required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          node.config.primitive.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: node.id.value,
          child: Text(
            'ID: ${node.id.value}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
