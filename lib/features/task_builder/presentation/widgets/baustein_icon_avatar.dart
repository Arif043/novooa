import 'package:flutter/material.dart';

import '../../domain/entities/workflow_node.dart';
import 'baustein_palette.dart';

/// Rundes Icon eines Bausteins auf der Leinwand.
class BausteinIconAvatar extends StatelessWidget {
  const BausteinIconAvatar({super.key, required this.primitive});

  static const _radius = 23.0;

  final WorkflowPrimitive primitive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: _radius,
      backgroundColor: colors.primaryContainer.withValues(alpha: .12),
      child: Icon(bausteinIcon(primitive), color: colors.primary),
    );
  }
}
