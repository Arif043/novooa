import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

/// Pin-Schalter im Panel: ob ein Wert als Chip auf der Leinwand steht.
class OutputCanvasToggle extends StatelessWidget {
  const OutputCanvasToggle({
    super.key,
    required this.showOnCanvas,
    required this.onChanged,
  });

  final bool showOnCanvas;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = showOnCanvas
        ? LocaleKeys.ui_hide_from_canvas.tr()
        : LocaleKeys.ui_show_on_canvas.tr();
    return IconButton(
      tooltip: label,
      isSelected: showOnCanvas,
      icon: const Icon(Icons.push_pin_outlined),
      selectedIcon: const Icon(Icons.push_pin),
      onPressed: () => onChanged(!showOnCanvas),
    );
  }
}
