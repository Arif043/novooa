import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Eine auswählbare Zeile der Zielwahl; [depth] rückt Verzeichnisse ein.
class EventTargetTile extends StatelessWidget {
  const EventTargetTile({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.depth = 0,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final int depth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: subtitle == null ? title : '$title, $subtitle',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 48,
        contentPadding: EdgeInsets.only(left: depth * AppSpacing.md),
        leading: Icon(icon, color: selected ? colors.primary : null),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: selected ? Icon(Icons.check, color: colors.primary) : null,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
