import 'package:flutter/material.dart';

/// Rundes Icon eines Bausteins auf der Leinwand.
class BausteinIconAvatar extends StatelessWidget {
  const BausteinIconAvatar({super.key, required this.icon});

  static const _radius = 23.0;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: _radius,
      backgroundColor: colors.primaryContainer.withValues(alpha: .12),
      child: Icon(icon, color: colors.primary),
    );
  }
}
