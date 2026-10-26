import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/locale_keys.g.dart';
import '../../../../core/theme/app_spacing.dart';

/// Hinweis an einem Baustein, dessen Plugin deaktiviert ist.
class PluginDisabledHint extends StatelessWidget {
  const PluginDisabledHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.extension_off_outlined,
          size: AppSpacing.md,
          color: colors.error,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            LocaleKeys.plugins_disabled_hint.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ),
      ],
    );
  }
}
