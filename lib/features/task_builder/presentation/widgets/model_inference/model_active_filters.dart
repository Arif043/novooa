import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import 'model_filter_sections.dart';

/// Gewählte Filter als entfernbare Chips über den Treffern, dazu „Filter zurücksetzen“.
class ModelActiveFilters extends StatelessWidget {
  const ModelActiveFilters({
    super.key,
    required this.options,
    required this.onReset,
  });

  final List<ModelFilterOption> options;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final option in options)
            InputChip(
              avatar: option.icon == null ? null : Icon(option.icon),
              label: Text(option.label),
              onDeleted: option.onToggle,
              deleteButtonTooltipMessage: LocaleKeys.ui_filter_entfernen.tr(
                namedArgs: {'label': option.label},
              ),
            ),
          TextButton(
            onPressed: onReset,
            child: Text(LocaleKeys.ui_filter_zuruecksetzen.tr()),
          ),
        ],
      ),
    );
  }
}
