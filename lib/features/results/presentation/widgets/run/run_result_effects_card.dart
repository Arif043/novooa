import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/luminous_card.dart';
import '../../../../activity/domain/entities/run_effect.dart';
import '../../../../activity/presentation/widgets/run_effects/open_effect_file.dart';
import '../../../../activity/presentation/widgets/run_effects/run_effect_list.dart';

/// Alle Folgen des Laufs; Dateien öffnen die Datei-Detailseite.
class RunResultEffectsCard extends StatelessWidget {
  const RunResultEffectsCard({super.key, required this.effects});

  final List<RunEffect> effects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LuminousCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: effects.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LocaleKeys.run_effects_title.tr(),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(LocaleKeys.results_no_effects.tr()),
                ],
              )
            : RunEffectList(
                effects: effects,
                onOpenFile: (effect) => openEffectFile(context, effect),
              ),
      ),
    );
  }
}
