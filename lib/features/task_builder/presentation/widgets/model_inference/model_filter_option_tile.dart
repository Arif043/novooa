import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'model_filter_sections.dart';

/// Eine Filteroption mit Trefferzahl. Bereiche und Aufgaben zeigen ihr Icon in der Akzentfarbe,
/// die übrigen ein Auswahlsymbol: rund bei Einfach-, eckig bei Mehrfachauswahl.
class ModelFilterOptionTile extends StatelessWidget {
  const ModelFilterOptionTile({
    super.key,
    required this.option,
    required this.multiSelect,
  });

  final ModelFilterOption option;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accented = option.icon != null || option.selected;
    return Semantics(
      checked: option.selected,
      inMutuallyExclusiveGroup: !multiSelect,
      child: ListTile(
        dense: true,
        selected: option.selected,
        selectedTileColor: colors.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        leading: ExcludeSemantics(
          child: Icon(
            _leadingIcon,
            color: accented ? colors.primary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(option.label, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          '${option.count}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        onTap: option.onToggle,
      ),
    );
  }

  IconData get _leadingIcon =>
      option.icon ??
      switch ((multiSelect, option.selected)) {
        (true, true) => Icons.check_box,
        (true, false) => Icons.check_box_outline_blank,
        (false, true) => Icons.radio_button_checked,
        (false, false) => Icons.radio_button_unchecked,
      };
}
