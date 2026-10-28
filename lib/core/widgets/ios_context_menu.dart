import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/syscat_theme.dart';

/// Ein Eintrag im Kontextmenü: Aktion oder Trennlinie.
sealed class IosContextMenuEntry<T> {
  const IosContextMenuEntry();
}

final class IosContextMenuItem<T> extends IosContextMenuEntry<T> {
  const IosContextMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.enabled = true,
  });

  final T value;
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool enabled;
}

final class IosContextMenuDivider<T> extends IosContextMenuEntry<T> {
  const IosContextMenuDivider();
}

/// Kompaktes Kontextmenü im iOS-Stil unter dem auslösenden Knopf: runde
/// Ecken, feine Kontur, Symbol und Text je Zeile, destruktive Aktionen rot.
/// [anchorContext] gehört zum Knopf, an dem das Menü hängt.
Future<T?> showIosContextMenu<T>(
  BuildContext anchorContext,
  List<IosContextMenuEntry<T>> entries,
) {
  final colors = Theme.of(anchorContext).colorScheme;
  return showMenu<T>(
    context: anchorContext,
    position: _positionBelow(anchorContext),
    color: colors.brightness == Brightness.dark
        ? SyscatTheme.menuSurfaceDark
        : colors.surface,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.sm + AppSpacing.xs),
      side: BorderSide(color: colors.outlineVariant),
    ),
    items: [
      for (final entry in entries)
        switch (entry) {
          IosContextMenuItem<T>() => PopupMenuItem<T>(
            value: entry.value,
            enabled: entry.enabled,
            height: _rowHeight,
            child: _MenuRow(item: entry),
          ),
          IosContextMenuDivider<T>() => const PopupMenuDivider(
            height: AppSpacing.sm,
          ),
        },
    ],
  );
}

/// Knopf mit Symbol, der das Kontextmenü öffnet und die Wahl meldet.
class IosContextMenuButton<T> extends StatelessWidget {
  const IosContextMenuButton({
    super.key,
    required this.tooltip,
    required this.entries,
    required this.onSelected,
    this.icon = Icons.more_horiz,
  });

  final String tooltip;
  final IconData icon;
  final List<IosContextMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) => IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: () async {
          final value = await showIosContextMenu(buttonContext, entries);
          if (value != null) onSelected(value);
        },
      ),
    );
  }
}

/// iOS empfiehlt mindestens 44 pt hohe Ziele; kompakter als Material (48).
const double _rowHeight = 44;

RelativeRect _positionBelow(BuildContext context) {
  final button = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final offset = button.localToGlobal(Offset.zero, ancestor: overlay);
  return RelativeRect.fromLTRB(
    offset.dx,
    offset.dy + button.size.height,
    overlay.size.width - offset.dx - button.size.width,
    overlay.size.height - offset.dy,
  );
}

class _MenuRow<T> extends StatelessWidget {
  const _MenuRow({required this.item});

  final IosContextMenuItem<T> item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = !item.enabled
        ? colors.onSurface.withValues(alpha: 0.38)
        : item.isDestructive
        ? colors.error
        : colors.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm + AppSpacing.xs / 2),
        Flexible(
          child: Text(
            item.label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
