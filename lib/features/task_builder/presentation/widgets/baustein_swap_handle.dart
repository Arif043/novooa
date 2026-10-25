import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../domain/entities/workflow_node.dart';
import '../cubits/node_config_labels.dart';
import 'baustein_icon_avatar.dart';

/// Baustein-Icon, über das ein Baustein auf einen anderen gezogen und mit ihm
/// getauscht wird. Gegriffen wird nur das Icon, damit Tippen auf die Node und
/// Verschieben der Leinwand frei bleiben; dem Zeiger folgt aber [feedback] in
/// Größe und Zoomstufe der Node hinter [sourceKey].
class BausteinSwapHandle extends StatelessWidget {
  const BausteinSwapHandle({
    super.key,
    required this.node,
    required this.sourceKey,
    required this.feedback,
    this.onDragStarted,
    this.onDragEnded,
  });

  final WorkflowNode node;
  final GlobalKey sourceKey;
  final Widget feedback;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnded;

  @override
  Widget build(BuildContext context) {
    final icon = BausteinIconAvatar(icon: node.config.icon);
    return Draggable<NodeId>(
      key: ValueKey('compact-node-drag-${node.id.value}'),
      data: node.id,
      dragAnchorStrategy: _anchorOnSource,
      feedback: _MeasuredFeedback(
        key: ValueKey('compact-node-drag-feedback-${node.id.value}'),
        sourceKey: sourceKey,
        child: feedback,
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded?.call(),
      child: Tooltip(
        message: LocaleKeys.task_builder_canvas_swap_block.tr(),
        child: icon,
      ),
    );
  }

  /// Hält den Griffpunkt fest: Die Node hängt dort am Zeiger, wo sie
  /// gegriffen wurde, statt mit der oberen linken Ecke am Icon.
  Offset _anchorOnSource(
    Draggable<Object> draggable,
    BuildContext context,
    Offset position,
  ) {
    final source = _sourceBox(sourceKey);
    if (source == null) {
      return childDragAnchorStrategy(draggable, context, position);
    }
    return source.globalToLocal(position) * _scaleOf(source);
  }
}

class _MeasuredFeedback extends StatelessWidget {
  const _MeasuredFeedback({
    super.key,
    required this.sourceKey,
    required this.child,
  });

  final GlobalKey sourceKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final source = _sourceBox(sourceKey);
    if (source == null) return const SizedBox.shrink();
    return Transform.scale(
      scale: _scaleOf(source),
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(size: source.size, child: child),
    );
  }
}

RenderBox? _sourceBox(GlobalKey key) {
  final box = key.currentContext?.findRenderObject();
  return box is RenderBox && box.hasSize ? box : null;
}

/// Zoomstufe der Leinwand, damit das Feedback so groß wie die Node erscheint.
double _scaleOf(RenderBox box) => box.getTransformTo(null).getMaxScaleOnAxis();
