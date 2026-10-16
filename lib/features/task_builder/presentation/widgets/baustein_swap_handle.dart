import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';

/// Baustein-Icon, über das ein Baustein auf einen anderen gezogen und mit ihm
/// getauscht wird. Beim Ziehen folgt das Icon selbst dem Zeiger.
class BausteinSwapHandle extends StatelessWidget {
  const BausteinSwapHandle({super.key, required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Draggable<NodeId>(
      key: ValueKey('compact-node-drag-${node.id.value}'),
      data: node.id,
      feedback: Material(
        key: ValueKey('compact-node-drag-feedback-${node.id.value}'),
        type: MaterialType.circle,
        // Deckend, weil der Avatar-Hintergrund halbtransparent ist und die
        // Leinwand sonst durch das gezogene Icon scheint.
        color: Theme.of(context).colorScheme.surface,
        elevation: 6,
        child: _BausteinIconAvatar(node: node),
      ),
      childWhenDragging: Opacity(
        opacity: .38,
        child: _BausteinIconAvatar(node: node),
      ),
      child: Tooltip(
        message: LocaleKeys.task_builder_canvas_swap_block.tr(),
        child: _BausteinIconAvatar(node: node),
      ),
    );
  }
}

class _BausteinIconAvatar extends StatelessWidget {
  const _BausteinIconAvatar({required this.node});

  static const _radius = 23.0;

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: _radius,
      backgroundColor: colors.primaryContainer.withValues(alpha: .12),
      child: Icon(bausteinIcon(node.config.primitive), color: colors.primary),
    );
  }
}
