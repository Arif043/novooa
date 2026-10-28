import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/run_effect.dart';
import 'run_effect_texts.dart';

/// Die Folgen eines Bausteins als kurze Liste; Dateien lassen sich öffnen.
class RunEffectList extends StatelessWidget {
  const RunEffectList({
    super.key,
    required this.effects,
    required this.onOpenFile,
  });

  final List<RunEffect> effects;
  final void Function(FileWrittenEffect effect) onOpenFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.run_effects_title.tr(),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final effect in effects)
          _EffectRow(
            effect: effect,
            onTap: effect is FileWrittenEffect
                ? () => onOpenFile(effect)
                : null,
          ),
      ],
    );
  }
}

class _EffectRow extends StatelessWidget {
  const _EffectRow({required this.effect, required this.onTap});

  final RunEffect effect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (:icon, :text) = runEffectPresentation(effect);
    return ListTile(
      dense: true,
      minTileHeight: AppSpacing.xxl,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colors.primary),
      title: Text(text),
      trailing: onTap == null
          ? null
          : Icon(
              Icons.open_in_new,
              semanticLabel: LocaleKeys.run_effects_open_file.tr(),
            ),
      onTap: onTap,
    );
  }
}
